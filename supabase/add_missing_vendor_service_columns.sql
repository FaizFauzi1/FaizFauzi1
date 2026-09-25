-- Migration to add missing columns to vendor_services table
-- Run this in your Supabase SQL Editor

ALTER TABLE vendor_services 
    ADD COLUMN IF NOT EXISTS logistics_config JSONB DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS time_rule JSONB DEFAULT '{}',
    ADD COLUMN IF NOT EXISTS original_price DECIMAL(10, 2),
    ADD COLUMN IF NOT EXISTS promo_expiry TIMESTAMP WITH TIME ZONE,
    ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Create a trigger to automatically update updated_at if not already present
-- Assuming update_modified_column() exists from previous migrations
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_trigger WHERE tgname = 'update_vendor_services_modtime') THEN
        CREATE TRIGGER update_vendor_services_modtime
            BEFORE UPDATE ON vendor_services
            FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
    END IF;
END $$;

COMMENT ON COLUMN vendor_services.logistics_config IS 'Stores logistics settings such as delivery fees and radius';
COMMENT ON COLUMN vendor_services.time_rule IS 'Stores time-based rules for service availability';
