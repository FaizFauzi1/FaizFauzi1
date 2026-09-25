-- Migration: Add Universal Promotion Columns to vendor_services
ALTER TABLE vendor_services 
ADD COLUMN IF NOT EXISTS original_price DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS promo_expiry TIMESTAMP WITH TIME ZONE;

-- Comment for documentation
COMMENT ON COLUMN vendor_services.original_price IS 'Original price before promotion for the base service';
COMMENT ON COLUMN vendor_services.promo_expiry IS 'Expiry date for the base service level promotion';
