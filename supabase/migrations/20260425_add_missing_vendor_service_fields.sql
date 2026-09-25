-- ADD MISSING FIELDS TO VENDOR_SERVICES FOR PRODUCT LOGISTICS AND BULK PRICING
ALTER TABLE public.vendor_services
ADD COLUMN IF NOT EXISTS bulk_pricing_tiers JSONB DEFAULT NULL,
ADD COLUMN IF NOT EXISTS variations JSONB DEFAULT NULL,
ADD COLUMN IF NOT EXISTS product_logistics JSONB DEFAULT NULL,
ADD COLUMN IF NOT EXISTS wedding_timeline JSONB DEFAULT NULL,
ADD COLUMN IF NOT EXISTS guarantee JSONB DEFAULT NULL,
ADD COLUMN IF NOT EXISTS video_url TEXT DEFAULT NULL;

COMMENT ON COLUMN public.vendor_services.bulk_pricing_tiers IS 'List of bulk pricing tiers for the service/product.';
COMMENT ON COLUMN public.vendor_services.variations IS 'List of product variations (e.g. size, color).';
COMMENT ON COLUMN public.vendor_services.product_logistics IS 'Logistics configuration specific to products (weight, dimensions, shipping classes).';
COMMENT ON COLUMN public.vendor_services.wedding_timeline IS 'Milestones and tasks for wedding preparation related to this service.';
COMMENT ON COLUMN public.vendor_services.guarantee IS 'Service guarantee or insurance details.';
COMMENT ON COLUMN public.vendor_services.video_url IS 'URL to a promotional or demonstration video for the service.';
