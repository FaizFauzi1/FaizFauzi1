-- Add country support to user tables and vendor profiles
-- Defaults existing records to Malaysia (MY)

-- Ensure countries table exists (idempotent)
CREATE TABLE IF NOT EXISTS public.countries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    code TEXT NOT NULL UNIQUE,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

INSERT INTO public.countries (id, name, code, is_active) VALUES
    ('640b489a-ad7a-4c6b-9dcd-e019851900f9', 'Malaysia', 'MY', true),
    ('740b489a-ad7a-4c6b-9dcd-e019851900fa', 'Singapore', 'SG', true),
    ('840b489a-ad7a-4c6b-9dcd-e019851900fb', 'Indonesia', 'ID', true)
ON CONFLICT (code) DO NOTHING;

-- Add country_code to user tables
ALTER TABLE public.customer_user
    ADD COLUMN IF NOT EXISTS country_code TEXT DEFAULT 'MY';

ALTER TABLE public.vendor_user
    ADD COLUMN IF NOT EXISTS country_code TEXT DEFAULT 'MY';

ALTER TABLE public.users
    ADD COLUMN IF NOT EXISTS country_code TEXT DEFAULT 'MY';

ALTER TABLE public.vendor_profiles
    ADD COLUMN IF NOT EXISTS country_code TEXT DEFAULT 'MY';

-- Backfill existing rows
UPDATE public.customer_user SET country_code = 'MY' WHERE country_code IS NULL;
UPDATE public.vendor_user SET country_code = 'MY' WHERE country_code IS NULL;
UPDATE public.users SET country_code = 'MY' WHERE country_code IS NULL;
UPDATE public.vendor_profiles SET country_code = 'MY' WHERE country_code IS NULL;

CREATE INDEX IF NOT EXISTS idx_customer_user_country ON public.customer_user(country_code);
CREATE INDEX IF NOT EXISTS idx_vendor_user_country ON public.vendor_user(country_code);
CREATE INDEX IF NOT EXISTS idx_vendor_profiles_country ON public.vendor_profiles(country_code);
