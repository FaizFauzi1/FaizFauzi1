-- Add expenses and expense budgets tables for vendor finance management
CREATE TABLE IF NOT EXISTS expenses (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    amount DECIMAL(10,2) NOT NULL,
    category TEXT NOT NULL,
    status TEXT NOT NULL DEFAULT 'pending',
    priority TEXT NOT NULL DEFAULT 'medium',
    date TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    due_date TIMESTAMP WITH TIME ZONE,
    receipt_image TEXT,
    approved_by UUID REFERENCES admin_user(id),
    approved_at TIMESTAMP WITH TIME ZONE,
    payment_reference TEXT,
    paid_at TIMESTAMP WITH TIME ZONE,
    metadata JSONB DEFAULT '{}',
    is_recurring BOOLEAN DEFAULT false,
    recurring_id UUID,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS expense_budgets (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    category TEXT NOT NULL,
    budgeted_amount DECIMAL(10,2) NOT NULL,
    spent_amount DECIMAL(10,2) DEFAULT 0.00,
    period_start TIMESTAMP WITH TIME ZONE NOT NULL,
    period_end TIMESTAMP WITH TIME ZONE NOT NULL,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(vendor_id, category, period_start, period_end)
);

-- Indexes
CREATE INDEX IF NOT EXISTS idx_expenses_vendor_id ON expenses(vendor_id);
CREATE INDEX IF NOT EXISTS idx_expenses_date ON expenses(date);
CREATE INDEX IF NOT EXISTS idx_expense_budgets_vendor_id ON expense_budgets(vendor_id);

-- RLS
ALTER TABLE expenses ENABLE ROW LEVEL SECURITY;
ALTER TABLE expense_budgets ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Vendors can manage their own expenses" ON expenses;
CREATE POLICY "Vendors can manage their own expenses" ON expenses
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = expenses.vendor_id
            AND user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Vendors can manage their own budgets" ON expense_budgets;
CREATE POLICY "Vendors can manage their own budgets" ON expense_budgets
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = expense_budgets.vendor_id
            AND user_id = auth.uid()
        )
    );
-- Add subscription-related columns and tables
ALTER TABLE vendor_profiles ADD COLUMN IF NOT EXISTS subscription_tier TEXT DEFAULT 'free';

-- Ensure subscription_tiers has all required columns (it might exist from other schema files)
CREATE TABLE IF NOT EXISTS subscription_tiers (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name TEXT NOT NULL,
    price DECIMAL(10,2) NOT NULL DEFAULT 0.00
);

-- Ensure UNIQUE constraint exists for ON CONFLICT (name)
DO $$ 
BEGIN 
    IF NOT EXISTS (
        SELECT 1 FROM pg_constraint 
        WHERE conname = 'subscription_tiers_name_key' 
        AND contype = 'u'
    ) THEN 
        ALTER TABLE subscription_tiers ADD CONSTRAINT subscription_tiers_name_key UNIQUE (name); 
    END IF; 
END $$;

-- Add missing columns individually for safety
ALTER TABLE subscription_tiers ADD COLUMN IF NOT EXISTS display_name TEXT;
ALTER TABLE subscription_tiers ADD COLUMN IF NOT EXISTS description TEXT;
ALTER TABLE subscription_tiers ADD COLUMN IF NOT EXISTS duration_days INTEGER;
ALTER TABLE subscription_tiers ADD COLUMN IF NOT EXISTS billing_cycle TEXT DEFAULT 'Monthly';
ALTER TABLE subscription_tiers ADD COLUMN IF NOT EXISTS features JSONB DEFAULT '[]';
ALTER TABLE subscription_tiers ADD COLUMN IF NOT EXISTS limits JSONB DEFAULT '{}';
ALTER TABLE subscription_tiers ADD COLUMN IF NOT EXISTS is_popular BOOLEAN DEFAULT false;
ALTER TABLE subscription_tiers ADD COLUMN IF NOT EXISTS sort_order INTEGER DEFAULT 0;
ALTER TABLE subscription_tiers ADD COLUMN IF NOT EXISTS is_active BOOLEAN DEFAULT true;
ALTER TABLE subscription_tiers ADD COLUMN IF NOT EXISTS created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
ALTER TABLE subscription_tiers ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- Create subscription_payments
CREATE TABLE IF NOT EXISTS subscription_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
    tier_id UUID NOT NULL REFERENCES subscription_tiers(id) ON DELETE CASCADE,
    amount DECIMAL(10,2) NOT NULL,
    payment_status TEXT DEFAULT 'pending',
    billing_period_start TIMESTAMP WITH TIME ZONE,
    billing_period_end TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Insert default tiers if they don't exist
INSERT INTO subscription_tiers (name, display_name, price, duration_days, billing_cycle, features, limits, sort_order)
VALUES 
('free', 'Free', 0.00, 30, 'Monthly', '["Basic listing", "Limited search visibility"]', '{"bookings": 5}', 0),
('basic', 'Basic', 29.00, 30, 'Monthly', '["Standard listing", "50 bookings/month", "Email support"]', '{"bookings": 50}', 1),
('professional', 'Professional', 59.00, 30, 'Monthly', '["Enhanced listing", "200 bookings/month", "Priority support", "Custom branding"]', '{"bookings": 200}', 2),
('premium', 'Premium', 99.00, 30, 'Monthly', '["Priority listing", "Unlimited bookings", "Premium support", "Advanced analytics"]', '{"bookings": -1}', 3)
ON CONFLICT (name) DO UPDATE SET
    display_name = EXCLUDED.display_name,
    price = EXCLUDED.price,
    duration_days = EXCLUDED.duration_days,
    features = EXCLUDED.features,
    limits = EXCLUDED.limits;

-- RLS for subscription tables
ALTER TABLE subscription_tiers ENABLE ROW LEVEL SECURITY;
ALTER TABLE subscription_payments ENABLE ROW LEVEL SECURITY;

-- Drop existing if conflict
DROP POLICY IF EXISTS "Anyone can view active subscription tiers" ON subscription_tiers;
CREATE POLICY "Anyone can view active subscription tiers" ON subscription_tiers
    FOR SELECT USING (is_active = true);

DROP POLICY IF EXISTS "Vendors can view their own payments" ON subscription_payments;
CREATE POLICY "Vendors can view their own payments" ON subscription_payments
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = subscription_payments.vendor_id
            AND user_id = auth.uid()
        )
    );
