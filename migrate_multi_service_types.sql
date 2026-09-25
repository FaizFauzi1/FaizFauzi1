-- Migration to support multiple service types per service
-- This adds 'service_types' column to store a list of types

ALTER TABLE vendor_services ADD COLUMN IF NOT EXISTS service_types JSONB DEFAULT '[]';

-- Migrate existing service_type to service_types list
UPDATE vendor_services 
SET service_types = jsonb_build_array(service_type)
WHERE service_types = '[]' OR service_types IS NULL;

-- Create an index for efficient searching in the jsonb array
CREATE INDEX IF NOT EXISTS idx_vendor_services_types ON vendor_services USING GIN (service_types);

-- Update RLS policies if they depend on service_type
-- (Usually they don't depend on the specific type value for basic access, 
-- but we should keep service_type column for backward compatibility for now)
