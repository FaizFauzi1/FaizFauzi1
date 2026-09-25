-- ============================================================
-- COUPON CODES & VOUCHERS
-- ============================================================

CREATE TABLE IF NOT EXISTS service_coupons (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id UUID REFERENCES vendor_services(id) ON DELETE CASCADE,
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    code TEXT NOT NULL,
    discount_type TEXT NOT NULL CHECK (discount_type IN ('percentage', 'flat')),
    discount_value NUMERIC NOT NULL,
    min_spend NUMERIC DEFAULT 0,
    max_discount NUMERIC, -- Cap for percentage discounts
    expiry_date TIMESTAMP WITH TIME ZONE,
    usage_limit INTEGER,
    current_usage INTEGER DEFAULT 0,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Ensure code is unique per service (or per vendor if service_id is NULL)
CREATE UNIQUE INDEX idx_unique_coupon_code_per_service ON service_coupons (service_id, code) WHERE service_id IS NOT NULL;
CREATE UNIQUE INDEX idx_unique_coupon_code_per_vendor ON service_coupons (vendor_id, code) WHERE service_id IS NULL;

-- Enable RLS
ALTER TABLE service_coupons ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Public can view active coupons" ON service_coupons
    FOR SELECT USING (is_active = true AND (expiry_date IS NULL OR expiry_date > NOW()));

CREATE POLICY "Vendors can manage own coupons" ON service_coupons
    FOR ALL USING (
        vendor_id IN (
            SELECT id FROM vendor_profiles WHERE user_id = auth.uid()
        )
    );

-- Trigger for updated_at
CREATE TRIGGER update_service_coupons_modtime
    BEFORE UPDATE ON service_coupons
    FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

-- RPC for atomic usage increment
CREATE OR REPLACE FUNCTION increment_coupon_usage(coupon_id UUID)
RETURNS void AS $$
BEGIN
    UPDATE service_coupons
    SET current_usage = current_usage + 1
    WHERE id = coupon_id;
END;
$$ LANGUAGE plpgsql;
