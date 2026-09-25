-- =============================================
-- FIX ADMIN BOOKING VISIBILITY
-- =============================================

-- 1. Enable RLS on bookings table (if not already enabled)
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- 2. Drop existing policies to avoid conflicts
DROP POLICY IF EXISTS "Admins can view all bookings" ON bookings;
DROP POLICY IF EXISTS "Vendors can view own bookings" ON bookings;
DROP POLICY IF EXISTS "Customers can view own bookings" ON bookings;

-- 3. Create RLS Policies for bookings

-- Admin access: View ALL bookings
CREATE POLICY "Admins can view all bookings" ON bookings
    FOR SELECT USING (
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'super_admin')
    );

-- Vendor access: View bookings for their own services
CREATE POLICY "Vendors can view own bookings" ON bookings
    FOR SELECT USING (
        vendor_id IN (SELECT id FROM vendor_profiles WHERE user_id = auth.uid())
    );

-- Customer access: View their own bookings
CREATE POLICY "Customers can view own bookings" ON bookings
    FOR SELECT USING (
        auth.uid() = customer_id
    );

-- 4. Create or Replace admin_bookings VIEW
-- This view flattens the booking data for the Admin Dashboard to match the Booking model
-- expected by AdminProvider._loadBookings

CREATE OR REPLACE VIEW admin_bookings AS
SELECT
    b.id,
    c.name AS user_name,
    v.business_name AS vendor_name,
    b.booking_date,
    b.total_amount AS amount,
    b.status,
    false AS priority, -- Default value as priority column doesn't exist in bookings
    b.created_at
FROM
    bookings b
JOIN
    customer_user c ON b.customer_id = c.id
JOIN
    vendor_profiles v ON b.vendor_id = v.id;

-- Grant access to the view
GRANT SELECT ON admin_bookings TO authenticated;
GRANT SELECT ON admin_bookings TO service_role;

-- 5. Verification Query (Optional - run manually to test)
-- SELECT * FROM admin_bookings LIMIT 5;
