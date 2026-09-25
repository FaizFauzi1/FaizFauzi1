-- Fix: organizer gets an RLS permission error (42501/403) when rejecting a
-- vendor's exhibitor application (UPDATE on organizer_exhibitors).
--
-- Root cause: migration 20260921_fix_exhibitor_apply_rls.sql made the admin
-- policies depend on public.current_user_role() reading the JWT 'role' claim.
-- Supabase always puts the Postgres role ('authenticated') in that claim, never
-- 'organizer'/'admin', so the admin policy never passes for organizers and the
-- reject UPDATE is denied (the only other permissive UPDATE policy is
-- vendor-scoped).
--
-- Fix: use SECURITY DEFINER helpers that resolve real identity from
-- public.users / public.admin_user / organizer membership tables, and split
-- policies per action.

-- ============================================================
-- Helper: is the current user a platform admin?
-- Roles live in public.users (admin/super_admin/vendor/customer/organizer) and
-- public.admin_user. SECURITY DEFINER lets the helper read them bypassing RLS.
-- ============================================================
CREATE OR REPLACE FUNCTION public.is_platform_admin()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.users
    WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
  )
  OR EXISTS (
    SELECT 1 FROM public.admin_user WHERE id = auth.uid()
  );
$$;

-- ============================================================
-- Helper: is the current user an organizer (company owner or active staff)?
-- SECURITY DEFINER so it can read membership tables regardless of RLS.
-- ============================================================
CREATE OR REPLACE FUNCTION public.is_organizer_user()
RETURNS BOOLEAN
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
STABLE
AS $$
  SELECT
    EXISTS (
      SELECT 1 FROM public.organizer_companies
      WHERE owner_user_id = auth.uid()
    )
    OR EXISTS (
      SELECT 1 FROM public.organizer_staff_members
      WHERE user_id = auth.uid() AND is_active = true
    );
$$;

-- ============================================================
-- organizer_exhibitors policies
-- ============================================================

-- Drop the broken catch-all admin policy from the previous migration.
DROP POLICY IF EXISTS "Admins manage organizer exhibitors" ON public.organizer_exhibitors;

-- INSERT: admins/organizers manage applicants; vendors create their own row.
DROP POLICY IF EXISTS "Organizers insert exhibitors" ON public.organizer_exhibitors;
CREATE POLICY "Organizers insert exhibitors"
    ON public.organizer_exhibitors FOR INSERT
    TO authenticated
    WITH CHECK (public.is_platform_admin() OR public.is_organizer_user());

DROP POLICY IF EXISTS "Vendors can apply as exhibitors" ON public.organizer_exhibitors;
CREATE POLICY "Vendors can apply as exhibitors"
    ON public.organizer_exhibitors FOR INSERT
    TO authenticated
    WITH CHECK (
        vendor_id = auth.uid()
        OR email = auth.jwt() ->> 'email'
    );

-- SELECT: organizers/admins see all; vendors see their own.
DROP POLICY IF EXISTS "Organizers view exhibitors" ON public.organizer_exhibitors;
CREATE POLICY "Organizers view exhibitors"
    ON public.organizer_exhibitors FOR SELECT
    TO authenticated
    USING (public.is_platform_admin() OR public.is_organizer_user());

DROP POLICY IF EXISTS "Vendors can view own exhibitor record" ON public.organizer_exhibitors;
CREATE POLICY "Vendors can view own exhibitor record"
    ON public.organizer_exhibitors FOR SELECT
    TO authenticated
    USING (
        vendor_id = auth.uid()
        OR email = auth.jwt() ->> 'email'
    );

-- UPDATE: organizers/admins manage status (approve/reject/etc.).
-- This is the policy that fixes the organizer REJECT error.
DROP POLICY IF EXISTS "Organizers update exhibitors" ON public.organizer_exhibitors;
CREATE POLICY "Organizers update exhibitors"
    ON public.organizer_exhibitors FOR UPDATE
    TO authenticated
    USING (public.is_platform_admin() OR public.is_organizer_user())
    WITH CHECK (public.is_platform_admin() OR public.is_organizer_user());

-- Vendors may edit only their own row's vendor-editable info, never invent rows.
DROP POLICY IF EXISTS "Vendors can update own exhibitor record" ON public.organizer_exhibitors;
CREATE POLICY "Vendors can update own exhibitor record"
    ON public.organizer_exhibitors FOR UPDATE
    TO authenticated
    USING (
        vendor_id = auth.uid()
        OR email = auth.jwt() ->> 'email'
    )
    WITH CHECK (
        vendor_id = auth.uid()
        OR email = auth.jwt() ->> 'email'
    );

-- DELETE: organizers/admins only.
DROP POLICY IF EXISTS "Organizers delete exhibitors" ON public.organizer_exhibitors;
CREATE POLICY "Organizers delete exhibitors"
    ON public.organizer_exhibitors FOR DELETE
    TO authenticated
    USING (public.is_platform_admin() OR public.is_organizer_user());

-- ============================================================
-- organizer_expos: same fix for its broken catch-all policy
-- ============================================================
DROP POLICY IF EXISTS "Admins manage organizer expos" ON public.organizer_expos;
CREATE POLICY "Organizers manage organizer expos"
    ON public.organizer_expos FOR ALL
    TO authenticated
    USING (public.is_platform_admin() OR public.is_organizer_user())
    WITH CHECK (public.is_platform_admin() OR public.is_organizer_user());

-- Keep public/vendor reads of expos working (public listing needs them).
DROP POLICY IF EXISTS "Anyone can view organizer expos" ON public.organizer_expos;
CREATE POLICY "Anyone can view organizer expos"
    ON public.organizer_expos FOR SELECT
    USING (true);