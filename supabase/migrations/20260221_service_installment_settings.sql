-- Add installment settings to vendor_services table
-- This allows vendors to configure installment options per service

ALTER TABLE public.vendor_services
ADD COLUMN IF NOT EXISTS installment_enabled BOOLEAN DEFAULT false,
ADD COLUMN IF NOT EXISTS deposit_percentage NUMERIC(5, 2),
ADD COLUMN IF NOT EXISTS max_installments INTEGER,
ADD COLUMN IF NOT EXISTS payment_deadline_days INTEGER;

-- Comments for documentation
COMMENT ON COLUMN public.vendor_services.installment_enabled IS 'Whether installment payments are enabled for this specific service.';
COMMENT ON COLUMN public.vendor_services.deposit_percentage IS 'Required deposit percentage for installments (0-100).';
COMMENT ON COLUMN public.vendor_services.max_installments IS 'Maximum number of installments allowed for this service.';
COMMENT ON COLUMN public.vendor_services.payment_deadline_days IS 'Number of days before the event by which payment must be completed.';
