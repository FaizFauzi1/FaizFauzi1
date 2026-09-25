-- Add business_hours and other missing columns to vendor_profiles if they don't exist
DO $$
BEGIN
    -- Add business_hours column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vendor_profiles' AND column_name = 'business_hours') THEN
        ALTER TABLE vendor_profiles ADD COLUMN business_hours JSONB DEFAULT '{}';
    END IF;

    -- Add service_areas column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vendor_profiles' AND column_name = 'service_areas') THEN
        ALTER TABLE vendor_profiles ADD COLUMN service_areas JSONB DEFAULT '[]';
    END IF;

    -- Add business_categories column if it doesn't exist (previously categories might have been used)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vendor_profiles' AND column_name = 'business_categories') THEN
        ALTER TABLE vendor_profiles ADD COLUMN business_categories JSONB DEFAULT '[]';
    END IF;
    
    -- Add logistics, amenities if they are being used by provider
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vendor_profiles' AND column_name = 'logistics') THEN
        ALTER TABLE vendor_profiles ADD COLUMN logistics JSONB DEFAULT '{}';
    END IF;

    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vendor_profiles' AND column_name = 'amenities') THEN
        ALTER TABLE vendor_profiles ADD COLUMN amenities JSONB DEFAULT '[]';
    END IF;

END $$;
