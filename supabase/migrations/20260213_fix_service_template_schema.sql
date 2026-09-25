-- Fix Service Template Schema Missing Columns
-- Run this in your Supabase SQL Editor

-- 1. Update service_pricing_tiers
ALTER TABLE public.service_pricing_tiers
ADD COLUMN IF NOT EXISTS original_price DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS promo_expiry TIMESTAMP WITH TIME ZONE;

-- 2. Update service_components
ALTER TABLE public.service_components
ADD COLUMN IF NOT EXISTS parent_component_id UUID REFERENCES public.service_components(id) ON DELETE CASCADE,
ADD COLUMN IF NOT EXISTS selection_limit INTEGER DEFAULT 0;

-- 3. Update service_items
ALTER TABLE public.service_items
ADD COLUMN IF NOT EXISTS gallery_urls TEXT[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS pdf_url TEXT,
ADD COLUMN IF NOT EXISTS applicable_tier_ids UUID[] DEFAULT '{}',
ADD COLUMN IF NOT EXISTS is_optional BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS extra_price DECIMAL(10, 2);
