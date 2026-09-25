-- Add rich media columns to service_items
ALTER TABLE service_items 
ADD COLUMN IF NOT EXISTS gallery_urls TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS pdf_url TEXT,
ADD COLUMN IF NOT EXISTS optional_service_id UUID REFERENCES vendor_services(id),
ADD COLUMN IF NOT EXISTS applicable_tier_ids UUID[] DEFAULT '{}';

-- Update RLS policies if needed (already broad enough from previous script)
