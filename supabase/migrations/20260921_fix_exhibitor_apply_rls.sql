-- Fix 42501 "permission denied for table users" blocking vendor exhibitor applications.
--
-- Root cause: permissive RLS policies on organizer_exhibitors / organizer_expos
-- contain subqueries against public.users (admin checks) and auth.users (email
-- matches). Postgres evaluates ALL permissive policies on an INSERT; the
-- vendor's session lacks SELECT on public.users / auth.users, so even a passing
-- vendor policy fails the whole statement with 42501.
--
-- Fix: stop reading profile tables in policies. Use JWT claims instead.

-- ============================================================
-- Helper: current user's role from JWT claims (no table access)
-- ============================================================
CREATE OR REPLACE FUNCTION public.current_user_role()
RETURNS TEXT
LANGUAGE sql
STABLE
AS $$
  SELECT COALESCE(
    NULLIF(current_setting('request.jwt.claim.role', true), ''),
    (current_setting('request.jwt.claims', true)::jsonb ->> 'role')
  );
$$;

-- ============================================================
-- organizer_exhibitors
-- ============================================================
DROP POLICY IF EXISTS "Admins manage organizer exhibitors" ON public.organizer_exhibitors;
CREATE POLICY "Admins manage organizer exhibitors"
    ON public.organizer_exhibitors FOR ALL
    USING (public.current_user_role() IN ('admin', 'super_admin', 'organizer'))
    WITH CHECK (public.current_user_role() IN ('admin', 'super_admin', 'organizer'));

DROP POLICY IF EXISTS "Vendors can view own exhibitor record" ON public.organizer_exhibitors;
CREATE POLICY "Vendors can view own exhibitor record"
    ON public.organizer_exhibitors FOR SELECT
    USING (
        vendor_id = auth.uid()
        OR email = auth.jwt() ->> 'email'
    );

DROP POLICY IF EXISTS "Vendors can apply as exhibitors" ON public.organizer_exhibitors;
CREATE POLICY "Vendors can apply as exhibitors"
    ON public.organizer_exhibitors FOR INSERT
    TO authenticated
    WITH CHECK (
        vendor_id = auth.uid()
        OR email = auth.jwt() ->> 'email'
    );

DROP POLICY IF EXISTS "Vendors can update own exhibitor record" ON public.organizer_exhibitors;
CREATE POLICY "Vendors can update own exhibitor record"
    ON public.organizer_exhibitors FOR UPDATE
    USING (
        vendor_id = auth.uid()
        OR email = auth.jwt() ->> 'email'
    );

-- ============================================================
-- organizer_expos: same fix for its admin policy
-- ============================================================
DROP POLICY IF EXISTS "Admins manage organizer expos" ON public.organizer_expos;
CREATE POLICY "Admins manage organizer expos"
    ON public.organizer_expos FOR ALL
    USING (public.current_user_role() IN ('admin', 'super_admin', 'organizer'))
    WITH CHECK (public.current_user_role() IN ('admin', 'super_admin', 'organizer'));