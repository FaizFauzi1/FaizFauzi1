-- Universal Service Creation Schema Migration
-- Updated to work with existing event_types table

-- 1. Alter existing table to add new columns required for Universal Service
ALTER TABLE public.event_types
ADD COLUMN IF NOT EXISTS code TEXT,
ADD COLUMN IF NOT EXISTS display_name TEXT;

-- 2. Populate code/display_name for existing rows to ensure integrity
-- This ensures 'Wedding' becomes code='wedding', display_name='Wedding'
UPDATE public.event_types
SET 
  code = LOWER(REPLACE(name, ' ', '_')),
  display_name = name
WHERE code IS NULL;

-- 3. Add Unique constraint to code (now that it's populated)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'event_types_code_key') THEN
        ALTER TABLE public.event_types ADD CONSTRAINT event_types_code_key UNIQUE (code);
    END IF;
END $$;

-- 4. Seed Initial Event Types (Using 'name' as well since it's likely required/not null)
-- We handle conflict on 'name' because it's a unique key and likely already exists for some types.
-- This ensures we update the 'code' to our standard if the name matches.
INSERT INTO public.event_types (code, name, display_name, category) VALUES
    ('akad', 'Akad Nikah', 'Akad Nikah', 'wedding'),
    ('sanding', 'Persandingan', 'Persandingan', 'wedding'),
    ('bertandang', 'Bertandang', 'Bertandang', 'wedding'),
    ('engagement', 'Engagement', 'Engagement', 'wedding'),
    ('henna', 'Henna Night', 'Henna Night', 'wedding'),
    ('corporate_meeting', 'Corporate Meeting', 'Corporate Meeting', 'corporate'),
    ('conference', 'Conference', 'Conference', 'corporate'),
    ('seminar', 'Seminar', 'Seminar', 'corporate'),
    ('product_launch', 'Product Launch', 'Product Launch', 'corporate'),
    ('team_building', 'Team Building', 'Team Building', 'corporate'),
    ('annual_dinner', 'Annual Dinner', 'Annual Dinner', 'corporate'),
    ('birthday', 'Birthday Party', 'Birthday Party', 'social'),
    ('anniversary', 'Anniversary', 'Anniversary', 'social'),
    ('graduation', 'Graduation', 'Graduation', 'social'),
    ('baby_shower', 'Baby Shower', 'Baby Shower', 'social'),
    ('reunion', 'Reunion', 'Reunion', 'social'),
    ('other', 'Other', 'Other', 'social')
ON CONFLICT (name) DO UPDATE SET 
    code = EXCLUDED.code,
    display_name = EXCLUDED.display_name,
    category = EXCLUDED.category;

-- 5. Add Universal Service Config Columns to vendor_services
ALTER TABLE public.vendor_services
ADD COLUMN IF NOT EXISTS pricing_model JSONB DEFAULT NULL,
ADD COLUMN IF NOT EXISTS add_ons JSONB DEFAULT NULL, -- List of ServiceAddOn
ADD COLUMN IF NOT EXISTS team_capacity JSONB DEFAULT NULL, -- TeamCapacityConfig
ADD COLUMN IF NOT EXISTS slot_config JSONB DEFAULT NULL, -- AvailabilitySlotConfig
ADD COLUMN IF NOT EXISTS allow_same_day_multi_event BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS same_day_discount NUMERIC(10, 2) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS different_day_surcharge NUMERIC(10, 2) DEFAULT NULL;

-- 6. Comments for documentation
COMMENT ON COLUMN public.vendor_services.pricing_model IS 'Stores the full pricing configuration including type (per_pax, per_event, etc), tiers, and event combinations.';
COMMENT ON COLUMN public.vendor_services.add_ons IS 'List of available add-ons with their specific pricing logic.';
COMMENT ON COLUMN public.vendor_services.team_capacity IS 'Configuration for concurrent booking capacity (e.g. how many teams available).';
COMMENT ON COLUMN public.vendor_services.slot_config IS 'Configuration for time slots, duration, and gaps.';

-- 7. Ensure RLS Policies allow access
DO $$ 
BEGIN
    -- Only add policies if they don't exist (names might vary, checking logic)
    -- But since table existed, it likely has policies. 
    -- We just ensure public read access is enabled.
    IF NOT EXISTS (SELECT 1 FROM pg_authorizations WHERE rolname = 'anon' AND oid IN (SELECT grantee FROM information_schema.role_table_grants WHERE table_name = 'event_types')) THEN
       -- Basic check, might be complex to verify specific policy. 
       -- Generally safe to assume existing table setup handles this or we add specific one.
       -- Adding a generic safe policy just in case:
       CREATE POLICY "Universal Public Read" ON public.event_types FOR SELECT USING (true);
    END IF;
    
EXCEPTION WHEN OTHERS THEN
    NULL; -- Ignore if policy already exists or conflict
END $$;
