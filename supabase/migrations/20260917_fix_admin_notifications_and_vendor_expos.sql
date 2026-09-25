-- Align vendor expo discovery with admin-managed organizer_expos,
-- and make admin_notifications insert/read/realtime reliable.

-- ─── Admin notifications ──────────────────────────────────────────────────
-- Drop FKs first — Postgres cannot change UUID → TEXT while FKs still exist.
DO $$
DECLARE
    rec RECORD;
BEGIN
    FOR rec IN
        SELECT con.conname
        FROM pg_constraint con
        JOIN pg_class rel ON rel.oid = con.conrelid
        JOIN pg_namespace nsp ON nsp.oid = rel.relnamespace
        WHERE nsp.nspname = 'public'
          AND rel.relname = 'admin_notifications'
          AND con.contype = 'f'
          AND EXISTS (
              SELECT 1
              FROM unnest(con.conkey) AS colnum
              JOIN pg_attribute att
                ON att.attrelid = con.conrelid
               AND att.attnum = colnum
              WHERE att.attname IN (
                  'related_user_id',
                  'related_vendor_id',
                  'related_booking_id'
              )
          )
    LOOP
        EXECUTE format(
            'ALTER TABLE public.admin_notifications DROP CONSTRAINT IF EXISTS %I',
            rec.conname
        );
    END LOOP;
END $$;

ALTER TABLE public.admin_notifications
    ALTER COLUMN related_user_id TYPE TEXT USING related_user_id::text,
    ALTER COLUMN related_vendor_id TYPE TEXT USING related_vendor_id::text,
    ALTER COLUMN related_booking_id TYPE TEXT USING related_booking_id::text;

ALTER TABLE public.admin_notifications ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Enable insert for authenticated users" ON public.admin_notifications;
CREATE POLICY "Enable insert for authenticated users"
    ON public.admin_notifications FOR INSERT
    TO authenticated
    WITH CHECK (true);

DROP POLICY IF EXISTS "Enable read for all users" ON public.admin_notifications;
DROP POLICY IF EXISTS "Admins read notifications" ON public.admin_notifications;
CREATE POLICY "Admins read notifications"
    ON public.admin_notifications FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
        OR EXISTS (
            SELECT 1 FROM public.admin_user
            WHERE id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Enable update for all users" ON public.admin_notifications;
DROP POLICY IF EXISTS "Admins update notifications" ON public.admin_notifications;
CREATE POLICY "Admins update notifications"
    ON public.admin_notifications FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
        OR EXISTS (
            SELECT 1 FROM public.admin_user
            WHERE id = auth.uid()
        )
    );

ALTER TABLE public.admin_notifications REPLICA IDENTITY FULL;

DO $$
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM pg_publication_tables
        WHERE pubname = 'supabase_realtime'
          AND schemaname = 'public'
          AND tablename = 'admin_notifications'
    ) THEN
        ALTER PUBLICATION supabase_realtime ADD TABLE public.admin_notifications;
    END IF;
EXCEPTION WHEN undefined_object THEN
    NULL;
END $$;

-- ─── Platform-hosted flag on expos ────────────────────────────────────────
ALTER TABLE public.organizer_expos
    ADD COLUMN IF NOT EXISTS is_platform_hosted BOOLEAN DEFAULT false;

ALTER TABLE public.organizer_expos
    ADD COLUMN IF NOT EXISTS description TEXT;

-- Vendors/customers can see published expos (same source as admin)
DROP POLICY IF EXISTS "Public and vendors view upcoming expos" ON public.organizer_expos;
CREATE POLICY "Public and vendors view upcoming expos"
    ON public.organizer_expos FOR SELECT
    USING (status IN ('upcoming', 'ongoing'));

DROP POLICY IF EXISTS "Admins manage organizer expos" ON public.organizer_expos;
CREATE POLICY "Admins manage organizer expos"
    ON public.organizer_expos FOR ALL
    USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
        OR EXISTS (
            SELECT 1 FROM public.admin_user
            WHERE id = auth.uid()
        )
    );

-- Extra exhibitor fields used by vendor apply flow
ALTER TABLE public.organizer_exhibitors
    ADD COLUMN IF NOT EXISTS vendor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL;

ALTER TABLE public.organizer_exhibitors DROP CONSTRAINT IF EXISTS organizer_exhibitors_status_check;
ALTER TABLE public.organizer_exhibitors
    ADD CONSTRAINT organizer_exhibitors_status_check
    CHECK (status IN (
        'pending', 'under_review', 'info_requested', 'approved',
        'payment_pending', 'confirmed', 'rejected', 'withdrawn', 'completed'
    ));

DROP POLICY IF EXISTS "Vendors can view own exhibitor record" ON public.organizer_exhibitors;
CREATE POLICY "Vendors can view own exhibitor record"
    ON public.organizer_exhibitors FOR SELECT
    USING (
        vendor_id = auth.uid()
        OR email = (SELECT email FROM auth.users WHERE id = auth.uid())
        OR vendor_profile_id IN (
            SELECT id FROM public.vendor_profiles WHERE user_id = auth.uid()
        )
    );

ALTER TABLE public.organizer_exhibitors
    ADD COLUMN IF NOT EXISTS preferred_booth TEXT,
    ADD COLUMN IF NOT EXISTS preferred_zone TEXT,
    ADD COLUMN IF NOT EXISTS tags TEXT[];

DROP POLICY IF EXISTS "Vendors can apply as exhibitors" ON public.organizer_exhibitors;
CREATE POLICY "Vendors can apply as exhibitors"
    ON public.organizer_exhibitors FOR INSERT
    TO authenticated
    WITH CHECK (
        vendor_id = auth.uid()
        OR vendor_profile_id IN (
            SELECT id FROM public.vendor_profiles WHERE user_id = auth.uid()
        )
        OR email = (SELECT email FROM auth.users WHERE id = auth.uid())
    );
