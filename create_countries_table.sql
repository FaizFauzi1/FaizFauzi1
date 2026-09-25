-- Migration: Create Countries Table and Update Regions
-- This adds support for multiple countries in the region management system

-- 1. Create countries table
CREATE TABLE IF NOT EXISTS public.countries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL UNIQUE,
    code TEXT UNIQUE, -- ISO country code (e.g., 'MY', 'SG')
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. Add country_id column to regions table (if it doesn't exist)
DO $$ 
BEGIN
    IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'regions' AND column_name = 'country_id'
    ) THEN
        ALTER TABLE public.regions 
        ADD COLUMN country_id UUID REFERENCES public.countries(id) ON DELETE CASCADE;
    END IF;
END $$;

-- 3. Insert Malaysia as the default country
INSERT INTO public.countries (id, name, code, is_active)
VALUES ('640b489a-ad7a-4c6b-9dcd-e019851900f9', 'Malaysia', 'MY', true)
ON CONFLICT (name) DO NOTHING;

-- 4. Update existing regions to reference Malaysia
UPDATE public.regions 
SET country_id = '640b489a-ad7a-4c6b-9dcd-e019851900f9'
WHERE country_id IS NULL;

-- 5. Add indexes for better performance
CREATE INDEX IF NOT EXISTS idx_regions_country_id ON public.regions(country_id);
CREATE INDEX IF NOT EXISTS idx_countries_code ON public.countries(code);
CREATE INDEX IF NOT EXISTS idx_countries_is_active ON public.countries(is_active);

-- 6. Enable RLS (Row Level Security) on countries table
ALTER TABLE public.countries ENABLE ROW LEVEL SECURITY;

-- 7. Create RLS policies for countries
-- Allow all authenticated users to read countries
CREATE POLICY "Allow authenticated users to read countries"
ON public.countries FOR SELECT
TO authenticated
USING (true);

-- Allow only admins to insert/update/delete countries
CREATE POLICY "Allow admins to manage countries"
ON public.countries FOR ALL
TO authenticated
USING (
    EXISTS (
        SELECT 1 FROM public.admin_user
        WHERE id = auth.uid()
    )
);

-- 8. Add some sample countries (optional)
INSERT INTO public.countries (name, code, is_active) VALUES
    ('Singapore', 'SG', true),
    ('Indonesia', 'ID', true),
    ('Thailand', 'TH', true),
    ('Philippines', 'PH', true)
ON CONFLICT (name) DO NOTHING;

COMMENT ON TABLE public.countries IS 'Stores countries for multi-country support in region management';
COMMENT ON COLUMN public.countries.code IS 'ISO 3166-1 alpha-2 country code';
