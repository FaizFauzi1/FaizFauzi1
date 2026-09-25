-- Add Preorder & Rental fields to vendor_services
ALTER TABLE public.vendor_services
ADD COLUMN IF NOT EXISTS min_order_qty integer,
ADD COLUMN IF NOT EXISTS production_days integer,
ADD COLUMN IF NOT EXISTS min_rental_days integer,
ADD COLUMN IF NOT EXISTS max_rental_days integer;

-- Update the realtime policies or anything else if necessary 
-- (Assuming they naturally inherit the table's existing policies)
