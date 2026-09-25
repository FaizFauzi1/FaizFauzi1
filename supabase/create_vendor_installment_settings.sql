-- Vendor Installment Settings Table
CREATE TABLE IF NOT EXISTS vendor_installment_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID REFERENCES vendor_user(id) ON DELETE CASCADE,
  
  -- Global vendor settings
  installments_enabled BOOLEAN DEFAULT true,
  default_deposit_percentage DECIMAL(5,2) DEFAULT 30.00,
  default_number_of_installments INTEGER DEFAULT 5,
  minimum_order_amount DECIMAL(10,2) DEFAULT 1000.00,
  payment_deadline_days INTEGER DEFAULT 7, -- Days before event for full payment
  
  -- Optional features
  allow_custom_plans BOOLEAN DEFAULT false,
  late_fee_enabled BOOLEAN DEFAULT false,
  late_fee_percentage DECIMAL(5,2) DEFAULT 5.00,
  grace_period_days INTEGER DEFAULT 3,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  UNIQUE(vendor_id)
);

-- Service-Specific Installment Settings Table
CREATE TABLE IF NOT EXISTS service_installment_settings (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  service_id UUID REFERENCES vendor_services(id) ON DELETE CASCADE,
  vendor_id UUID REFERENCES vendor_user(id) ON DELETE CASCADE,
  
  -- Service-specific overrides (NULL means use vendor default)
  installments_enabled BOOLEAN,
  deposit_percentage DECIMAL(5,2),
  number_of_installments INTEGER,
  minimum_amount DECIMAL(10,2),
  payment_deadline_days INTEGER,
  
  created_at TIMESTAMP DEFAULT NOW(),
  updated_at TIMESTAMP DEFAULT NOW(),
  
  UNIQUE(service_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_vendor_installment_settings_vendor_id 
  ON vendor_installment_settings(vendor_id);
CREATE INDEX IF NOT EXISTS idx_service_installment_settings_service_id 
  ON service_installment_settings(service_id);
CREATE INDEX IF NOT EXISTS idx_service_installment_settings_vendor_id 
  ON service_installment_settings(vendor_id);

-- Insert default settings for existing vendors (optional migration)
-- INSERT INTO vendor_installment_settings (vendor_id)
-- SELECT id FROM vendor_user
-- WHERE id NOT IN (SELECT vendor_id FROM vendor_installment_settings);
