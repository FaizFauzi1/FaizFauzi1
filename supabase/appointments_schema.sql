-- Appointments System Schema
-- Run this SQL in your Supabase SQL Editor

-- 1. Appointments Table
CREATE TABLE IF NOT EXISTS appointments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    vendor_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    service_id UUID REFERENCES vendor_services(id) ON DELETE SET NULL,
    event_id UUID,
    type TEXT NOT NULL CHECK (type IN ('foodTasting', 'fitting', 'siteVisit', 'trial', 'consultation', 'pickup', 'delivery', 'returnItem')),
    scheduled_date TIMESTAMPTZ NOT NULL,
    duration_minutes INTEGER NOT NULL DEFAULT 60,
    location TEXT NOT NULL,
    notes TEXT DEFAULT '',
    status TEXT NOT NULL DEFAULT 'pending' CHECK (status IN ('pending', 'confirmed', 'completed', 'cancelled', 'noShow')),
    cost DECIMAL(10, 2),
    is_paid BOOLEAN NOT NULL DEFAULT false,
    reminder BOOLEAN NOT NULL DEFAULT true,
    created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMPTZ,
    
    -- Additional fields for display
    customer_name TEXT,
    customer_email TEXT,
    vendor_name TEXT,
    service_name TEXT,
    
    -- Chat integration
    chat_message_id UUID,
    source TEXT DEFAULT 'manual' CHECK (source IN ('manual', 'chat', 'booking'))
);

-- Create Indexes for Performance
CREATE INDEX IF NOT EXISTS idx_appointments_vendor_id ON appointments(vendor_id);
CREATE INDEX IF NOT EXISTS idx_appointments_customer_id ON appointments(customer_id);
CREATE INDEX IF NOT EXISTS idx_appointments_scheduled_date ON appointments(scheduled_date DESC);
CREATE INDEX IF NOT EXISTS idx_appointments_status ON appointments(status);
CREATE INDEX IF NOT EXISTS idx_appointments_service_id ON appointments(service_id);
CREATE INDEX IF NOT EXISTS idx_appointments_chat_message_id ON appointments(chat_message_id);

-- Enable Row Level Security (RLS)
ALTER TABLE appointments ENABLE ROW LEVEL SECURITY;

-- RLS Policies for appointments

-- Customers can view their own appointments
CREATE POLICY "Customers can view own appointments"
    ON appointments FOR SELECT
    USING (auth.uid() = customer_id);

-- Customers can create appointments
CREATE POLICY "Customers can create appointments"
    ON appointments FOR INSERT
    WITH CHECK (auth.uid() = customer_id);

-- Customers can update their own pending appointments
CREATE POLICY "Customers can update own pending appointments"
    ON appointments FOR UPDATE
    USING (auth.uid() = customer_id AND status = 'pending');

-- Vendors can view their appointments
CREATE POLICY "Vendors can view own appointments"
    ON appointments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM vendor_user
            WHERE vendor_user.id = auth.uid()
        )
        AND auth.uid() = vendor_id
    );

-- Vendors can update their appointments (confirm, complete, cancel)
CREATE POLICY "Vendors can update own appointments"
    ON appointments FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM vendor_user
            WHERE vendor_user.id = auth.uid()
        )
        AND auth.uid() = vendor_id
    );

-- Admins can view all appointments
CREATE POLICY "Admins can view all appointments"
    ON appointments FOR SELECT
    USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE admin_user.id = auth.uid()
        )
    );

-- Admins can update all appointments
CREATE POLICY "Admins can update all appointments"
    ON appointments FOR UPDATE
    USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE admin_user.id = auth.uid()
        )
    );

-- Enable real-time for appointments
ALTER PUBLICATION supabase_realtime ADD TABLE appointments;

-- Function to automatically update updated_at timestamp
CREATE OR REPLACE FUNCTION update_appointments_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to call the function
CREATE TRIGGER appointments_updated_at_trigger
    BEFORE UPDATE ON appointments
    FOR EACH ROW
    EXECUTE FUNCTION update_appointments_updated_at();
