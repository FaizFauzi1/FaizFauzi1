-- Migration: Add Promotion Columns to Service Pricing Tiers
ALTER TABLE service_pricing_tiers 
ADD COLUMN IF NOT EXISTS original_price DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS promo_expiry TIMESTAMP WITH TIME ZONE;
