-- CREATE ADMIN PAYOUTS AND ACTIVITY LOG TABLES
-- This script adds the missing tables for the Admin Dashboard payout and activity features.

-- 1. Create admin_payouts table
CREATE TABLE IF NOT EXISTS admin_payouts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_name TEXT NOT NULL,
    vendor_id UUID REFERENCES vendor_profiles(id) ON DELETE SET NULL,
    bank_account_id UUID, -- This will reference vendor_banking(id) in practice
    amount DECIMAL(12, 2) NOT NULL,
    status TEXT DEFAULT 'pending', -- pending / paid / failed
    payment_method TEXT DEFAULT 'fpx',
    processed_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for admin_payouts
ALTER TABLE admin_payouts ENABLE ROW LEVEL SECURITY;

-- Add policies for admin users
-- Assume there is an admin_user table or role
CREATE POLICY "Admins can manage payouts" ON admin_payouts
    FOR ALL USING (auth.uid() IN (SELECT id FROM admin_user));

-- 2. Create admin_activity_log table (if it doesn't already exist)
CREATE TABLE IF NOT EXISTS admin_activity_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    subtitle TEXT,
    activity_type TEXT, -- system / payment / registration / dispute
    action TEXT,
    actor_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for admin_activity_log
ALTER TABLE admin_activity_log ENABLE ROW LEVEL SECURITY;

-- Add policies for admin users
CREATE POLICY "Admins can view activity logs" ON admin_activity_log
    FOR SELECT USING (auth.uid() IN (SELECT id FROM admin_user));

-- 3. Trigger for update_at
CREATE TRIGGER update_admin_payouts_modtime
    BEFORE UPDATE ON admin_payouts
    FOR EACH ROW EXECUTE PROCEDURE update_modified_column();
