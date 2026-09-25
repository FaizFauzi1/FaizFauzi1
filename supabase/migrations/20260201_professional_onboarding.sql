-- PROFESSIONAL VENDOR ONBOARDING SCHEMA

-- Utility function for updating timestamps
CREATE OR REPLACE FUNCTION update_modified_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- A. Business Information (Enhancing existing vendor_profiles)
ALTER TABLE vendor_profiles 
ADD COLUMN IF NOT EXISTS legal_business_name TEXT,
ADD COLUMN IF NOT EXISTS trading_name TEXT,
ADD COLUMN IF NOT EXISTS business_type TEXT, -- Sole Prop / Sdn Bhd / Partnership / Individual
ADD COLUMN IF NOT EXISTS ssm_number TEXT,
ADD COLUMN IF NOT EXISTS ssm_expiry_date DATE,
ADD COLUMN IF NOT EXISTS business_registration_address TEXT,
ADD COLUMN IF NOT EXISTS operating_address TEXT,
ADD COLUMN IF NOT EXISTS social_instagram TEXT,
ADD COLUMN IF NOT EXISTS social_tiktok TEXT,
ADD COLUMN IF NOT EXISTS business_start_year INTEGER,
ADD COLUMN IF NOT EXISTS staff_count INTEGER,
ADD COLUMN IF NOT EXISTS peak_season_capacity_per_month INTEGER;

-- B. Owner / PIC Details (New Table)
CREATE TABLE IF NOT EXISTS vendor_owners (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    full_name TEXT NOT NULL,
    ic_number TEXT NOT NULL,
    date_of_birth DATE,
    nationality TEXT,
    phone_number TEXT NOT NULL,
    whatsapp_number TEXT,
    email TEXT NOT NULL,
    emergency_contact TEXT,
    role TEXT NOT NULL, -- Owner / Manager
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for vendor_owners
ALTER TABLE vendor_owners ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vendors can view own owner details" ON vendor_owners
    FOR SELECT USING (auth.uid() IN (
        SELECT user_id FROM vendor_profiles WHERE id = vendor_owners.vendor_id
    ));

CREATE POLICY "Vendors can update own owner details" ON vendor_owners
    FOR UPDATE USING (auth.uid() IN (
        SELECT user_id FROM vendor_profiles WHERE id = vendor_owners.vendor_id
    ));

CREATE POLICY "Vendors can insert own owner details" ON vendor_owners
    FOR INSERT WITH CHECK (auth.uid() IN (
        SELECT user_id FROM vendor_profiles WHERE id = vendor_owners.vendor_id
    ));


-- C. Banking & Payment (New Table)
CREATE TABLE IF NOT EXISTS vendor_banking (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    bank_name TEXT NOT NULL,
    account_holder_name TEXT NOT NULL,
    account_number TEXT NOT NULL,
    fpx_enabled BOOLEAN DEFAULT FALSE,
    ewallet_support JSONB, -- Array of supported e-wallets
    payout_preference TEXT, -- Weekly / Monthly
    tax_number TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for vendor_banking
ALTER TABLE vendor_banking ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vendors can view own banking details" ON vendor_banking
    FOR SELECT USING (auth.uid() IN (
        SELECT user_id FROM vendor_profiles WHERE id = vendor_banking.vendor_id
    ));

CREATE POLICY "Vendors can update own banking details" ON vendor_banking
    FOR UPDATE USING (auth.uid() IN (
        SELECT user_id FROM vendor_profiles WHERE id = vendor_banking.vendor_id
    ));

CREATE POLICY "Vendors can insert own banking details" ON vendor_banking
    FOR INSERT WITH CHECK (auth.uid() IN (
        SELECT user_id FROM vendor_profiles WHERE id = vendor_banking.vendor_id
    ));


-- D. Service Capability & E. Pricing & Packages (Enhancing vendor_profiles & vendor_services)
-- Adding general vendor capability fields to vendor_profiles
ALTER TABLE vendor_profiles
ADD COLUMN IF NOT EXISTS coverage_area_state TEXT,
ADD COLUMN IF NOT EXISTS coverage_area_city TEXT,
ADD COLUMN IF NOT EXISTS coverage_radius_km INTEGER,
ADD COLUMN IF NOT EXISTS service_max_pax INTEGER,
ADD COLUMN IF NOT EXISTS min_order_amount DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS setup_time_hours DECIMAL(4, 2),
ADD COLUMN IF NOT EXISTS breakdown_time_hours DECIMAL(4, 2),
ADD COLUMN IF NOT EXISTS team_size_per_event INTEGER,
ADD COLUMN IF NOT EXISTS equipment_provided TEXT, -- Description
ADD COLUMN IF NOT EXISTS backup_team_available BOOLEAN DEFAULT FALSE;

-- Adding Pricing Policies to vendor_profiles
ALTER TABLE vendor_profiles
ADD COLUMN IF NOT EXISTS starting_price DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS price_per_pax DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS weekend_surcharge_percent DECIMAL(5, 2),
ADD COLUMN IF NOT EXISTS peak_season_surcharge_percent DECIMAL(5, 2),
ADD COLUMN IF NOT EXISTS overtime_rate_per_hour DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS travel_fee_per_km DECIMAL(10, 2),
ADD COLUMN IF NOT EXISTS deposit_required_percent DECIMAL(5, 2),
ADD COLUMN IF NOT EXISTS cancellation_policy_days INTEGER,
ADD COLUMN IF NOT EXISTS cancellation_refund_percent DECIMAL(5, 2),
ADD COLUMN IF NOT EXISTS reschedule_allowed BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS damage_policy TEXT;


-- F. Availability & Operations (New Table or JSONB in profiles? Let's use JSONB for flexibility but columns for querying)
ALTER TABLE vendor_profiles
ADD COLUMN IF NOT EXISTS operating_days JSONB, -- Array of days e.g., ["Mon", "Tue"]
ADD COLUMN IF NOT EXISTS operating_hours_start TIME,
ADD COLUMN IF NOT EXISTS operating_hours_end TIME,
ADD COLUMN IF NOT EXISTS blackout_dates JSONB, -- Array of dates
ADD COLUMN IF NOT EXISTS max_bookings_per_day INTEGER DEFAULT 1,
ADD COLUMN IF NOT EXISTS lead_time_days INTEGER DEFAULT 3,
ADD COLUMN IF NOT EXISTS same_day_booking_allowed BOOLEAN DEFAULT FALSE;


-- G. Compliance & Trust (Enhancing vendor_profiles documents JSONB is already there, but adding specific status columns)
ALTER TABLE vendor_profiles
ADD COLUMN IF NOT EXISTS ic_upload_url TEXT,
ADD COLUMN IF NOT EXISTS ssm_cert_url TEXT,
ADD COLUMN IF NOT EXISTS bank_statement_url TEXT,
ADD COLUMN IF NOT EXISTS insurance_policy_url TEXT,
ADD COLUMN IF NOT EXISTS halal_cert_url TEXT,
ADD COLUMN IF NOT EXISTS past_client_references JSONB, -- Array of strings/objects
ADD COLUMN IF NOT EXISTS agreed_to_terms BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS agreed_to_sla BOOLEAN DEFAULT FALSE;


-- H. App System Fields (Enhancing vendor_profiles)
ALTER TABLE vendor_profiles
ADD COLUMN IF NOT EXISTS verification_level TEXT DEFAULT 'basic', -- basic / verified / premium
ADD COLUMN IF NOT EXISTS performance_score DECIMAL(5, 2) DEFAULT 0.0,
ADD COLUMN IF NOT EXISTS response_time_avg_minutes INTEGER,
ADD COLUMN IF NOT EXISTS job_completion_rate DECIMAL(5, 2),
ADD COLUMN IF NOT EXISTS no_show_rate DECIMAL(5, 2);

-- Trigger to update updated_at for new tables
CREATE TRIGGER update_vendor_owners_modtime
    BEFORE UPDATE ON vendor_owners
    FOR EACH ROW EXECUTE PROCEDURE update_modified_column();

CREATE TRIGGER update_vendor_banking_modtime
    BEFORE UPDATE ON vendor_banking
    FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
