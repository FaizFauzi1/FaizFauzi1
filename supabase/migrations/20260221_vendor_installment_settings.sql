-- Create vendor_installment_settings table
CREATE TABLE IF NOT EXISTS vendor_installment_settings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_user(id) ON DELETE CASCADE,
    is_enabled BOOLEAN DEFAULT false,
    deposit_percentage DECIMAL(5,2) DEFAULT 30.00,
    max_installments INTEGER DEFAULT 5,
    min_order_amount DECIMAL(10,2) DEFAULT 500.00,
    payment_deadline_days INTEGER DEFAULT 30, -- Days before event
    allow_custom_plans BOOLEAN DEFAULT false,
    late_fee_percentage DECIMAL(5,2) DEFAULT 5.00,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(vendor_id)
);

-- Enable RLS
ALTER TABLE vendor_installment_settings ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Vendors can manage their own installment settings" 
    ON vendor_installment_settings 
    FOR ALL 
    USING (auth.uid() = vendor_id);

CREATE POLICY "Anyone can view vendor installment settings" 
    ON vendor_installment_settings 
    FOR SELECT 
    USING (true);

-- Trigger for updated_at
CREATE OR REPLACE FUNCTION update_vendor_installment_settings_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER vendor_installment_settings_updated_at_trigger
    BEFORE UPDATE ON vendor_installment_settings
    FOR EACH ROW
    EXECUTE FUNCTION update_vendor_installment_settings_updated_at();
