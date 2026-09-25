-- HIERARCHICAL COMMISSION & FEE TRANSPARENCY MIGRATION

-- 1. ADAPT VENDOR PROFILES (Vendor-level commission)
ALTER TABLE public.vendor_profiles
ADD COLUMN IF NOT EXISTS commission_rate NUMERIC(5, 2) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS commission_override BOOLEAN DEFAULT false;

COMMENT ON COLUMN public.vendor_profiles.commission_rate IS 'Custom commission percentage for this vendor. Overrides global system rate.';
COMMENT ON COLUMN public.vendor_profiles.commission_override IS 'If true, this specific commission rate is locked and won''t be affected by global changes.';

-- 2. ADAPT VENDOR SERVICES (Service-level commission & Fee transparency)
ALTER TABLE public.vendor_services
ADD COLUMN IF NOT EXISTS commission_rate NUMERIC(5, 2) DEFAULT NULL,
ADD COLUMN IF NOT EXISTS commission_override BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS is_transport_included BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS is_accommodation_included BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS is_setup_included BOOLEAN DEFAULT true,
ADD COLUMN IF NOT EXISTS other_fees_description TEXT DEFAULT NULL;

COMMENT ON COLUMN public.vendor_services.commission_rate IS 'Custom commission percentage for this specific service. Overrides vendor and global rates.';
COMMENT ON COLUMN public.vendor_services.is_transport_included IS 'Whether transport/mileage is included in the base price.';
COMMENT ON COLUMN public.vendor_services.is_accommodation_included IS 'Whether accommodation (if required) is included in the base price.';
COMMENT ON COLUMN public.vendor_services.is_setup_included IS 'Whether setup/teardown is included in the base price.';

-- 3. ENSURE ADMINS CAN MANAGE (RLS)
-- Assuming existing RLS allows admins to update these tables.
-- Adding specific policy for admin management of these new fields if needed.
-- In Supabase, usually 'service_role' or 'admin' users have full access.
-- We ensure the vendor_profiles and vendor_services have appropriate update policies.

-- Note: No specific new policies required if standard 'authenticated' / 'admin' logic applies.
