-- Migration to create missing tables for Booking Reschedule Flow

-- 1. Create vendor_service_packages table
CREATE TABLE IF NOT EXISTS vendor_service_packages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id UUID NOT NULL REFERENCES vendor_services(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'General',
    price DECIMAL(10,2) NOT NULL DEFAULT 0.00,
    priceByPax JSONB DEFAULT '{}', -- Match Dart model name for easy mapping
    facilities TEXT[] DEFAULT '{}',
    services TEXT[] DEFAULT '{}',
    photography TEXT[] DEFAULT '{}',
    additionalDetails JSONB DEFAULT '{}',
    is_active BOOLEAN DEFAULT true,
    approval_status TEXT DEFAULT 'approved' CHECK (approval_status IN ('pending', 'approved', 'rejected')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create booking_changes table
CREATE TABLE IF NOT EXISTS booking_changes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    booking_id UUID NOT NULL REFERENCES bookings(id) ON DELETE CASCADE,
    requested_by UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    change_type TEXT NOT NULL CHECK (change_type IN ('date', 'package', 'pax', 'add_on', 'other')),
    old_value JSONB DEFAULT '{}',
    new_value JSONB DEFAULT '{}',
    price_diff DECIMAL(10,2) DEFAULT 0.00,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'approved', 'rejected', 'completed', 'cancelled')),
    vendor_notes TEXT,
    customer_notes TEXT,
    resolved_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. RLS Policies for vendor_service_packages
ALTER TABLE vendor_service_packages ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Public can view active packages" ON vendor_service_packages
    FOR SELECT USING (is_active = true AND approval_status = 'approved');

CREATE POLICY "Vendors can manage their own service packages" ON vendor_service_packages
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM vendor_services
            JOIN vendor_profiles ON vendor_services.vendor_id = vendor_profiles.id
            WHERE vendor_services.id = vendor_service_packages.service_id
            AND vendor_profiles.user_id = auth.uid()
        )
    );

-- 4. RLS Policies for booking_changes
ALTER TABLE booking_changes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own booking changes" ON booking_changes
    FOR SELECT USING (
        auth.uid() = requested_by OR
        EXISTS (
            SELECT 1 FROM bookings
            JOIN vendor_profiles ON bookings.vendor_id = vendor_profiles.id
            WHERE bookings.id = booking_changes.booking_id
            AND (bookings.customer_id = auth.uid() OR vendor_profiles.user_id = auth.uid())
        )
    );

CREATE POLICY "Customers can request booking changes" ON booking_changes
    FOR INSERT WITH CHECK (
        auth.uid() = requested_by
    );

CREATE POLICY "Vendors and customers can update booking changes" ON booking_changes
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM bookings
            JOIN vendor_profiles ON bookings.vendor_id = vendor_profiles.id
            WHERE bookings.id = booking_changes.booking_id
            AND (bookings.customer_id = auth.uid() OR vendor_profiles.user_id = auth.uid())
        )
    );

-- Seed some sample packages for existing services
INSERT INTO vendor_service_packages (service_id, name, description, price, priceByPax)
SELECT id, 'Essential Package', 'Basic features for small events', base_price * 0.8, '{"50": 1000, "100": 1800}'::JSONB
FROM vendor_services 
LIMIT 5;

INSERT INTO vendor_service_packages (service_id, name, description, price, priceByPax)
SELECT id, 'Premium Plus', 'Complete coverage with all add-ons', base_price * 1.5, '{"50": 2500, "100": 4500}'::JSONB
FROM vendor_services 
LIMIT 5;

-- Indexes
CREATE INDEX IF NOT EXISTS idx_vsp_service_id ON vendor_service_packages(service_id);
CREATE INDEX IF NOT EXISTS idx_bc_booking_id ON booking_changes(booking_id);
CREATE INDEX IF NOT EXISTS idx_bc_requested_by ON booking_changes(requested_by);
CREATE INDEX IF NOT EXISTS idx_bc_status ON booking_changes(status);
