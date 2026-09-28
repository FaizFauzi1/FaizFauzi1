CREATE TABLE IF NOT EXISTS public.admin_system_settings (
    id TEXT PRIMARY KEY,
    maintenance_mode BOOLEAN NOT NULL DEFAULT false,
    feature_flags JSONB NOT NULL DEFAULT '{}'::jsonb,
    commission_percent NUMERIC(5, 2) NOT NULL DEFAULT 10.00
        CHECK (commission_percent >= 0 AND commission_percent <= 100),
    updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    CONSTRAINT admin_system_settings_singleton CHECK (id = 'system_settings')
);

ALTER TABLE public.admin_system_settings
    ADD COLUMN IF NOT EXISTS maintenance_mode BOOLEAN NOT NULL DEFAULT false,
    ADD COLUMN IF NOT EXISTS feature_flags JSONB NOT NULL DEFAULT '{}'::jsonb,
    ADD COLUMN IF NOT EXISTS commission_percent NUMERIC(5, 2) NOT NULL DEFAULT 10.00,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW();

ALTER TABLE public.admin_system_settings ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public can read admin system settings"
    ON public.admin_system_settings;
CREATE POLICY "Public can read admin system settings"
    ON public.admin_system_settings
    FOR SELECT TO anon, authenticated
    USING (true);

DROP POLICY IF EXISTS "Admins can manage admin system settings"
    ON public.admin_system_settings;
CREATE POLICY "Admins can manage admin system settings"
    ON public.admin_system_settings
    FOR ALL TO authenticated
    USING (EXISTS (SELECT 1 FROM public.admin_user WHERE id = auth.uid()))
    WITH CHECK (EXISTS (SELECT 1 FROM public.admin_user WHERE id = auth.uid()));

GRANT SELECT ON public.admin_system_settings TO anon, authenticated;
GRANT INSERT, UPDATE ON public.admin_system_settings TO authenticated;

INSERT INTO public.admin_system_settings (
    id,
    maintenance_mode,
    feature_flags,
    commission_percent
)
VALUES (
    'system_settings',
    false,
    '{
        "Vendor Registration": true,
        "Booking System": true,
        "In-App Messaging": true,
        "Reviews & Ratings": true,
        "Promotions & Ads": true,
        "Articles & Content": true,
        "Payment System": true
    }'::jsonb,
    10.00
)
ON CONFLICT (id) DO NOTHING;