-- =============================================
-- FIX: "admin_bookings is not a view" ERROR
-- =============================================
-- If you see an error saying "admin_bookings is not a view", 
-- it means a TABLE with that name was created earlier (perhaps by a migration or initial schema).
-- We need to drop the table first, then create the view.

-- 1. DROP the colliding TABLE (if it exists)
DROP TABLE IF EXISTS admin_bookings CASCADE;

-- 2. DROP the VIEW (if it exists, just to be sure)
DROP VIEW IF EXISTS admin_bookings CASCADE;

-- 3. Ensure Role Consistency
-- Update 'users' table role to 'admin' for anyone who is in 'admin_user' table
UPDATE users 
SET role = 'admin' 
WHERE id IN (SELECT id FROM admin_user) AND role != 'admin';

-- 4. Create proper admin_bookings VIEW
-- This view flattens the booking data for the Admin Dashboard
-- Uses LEFT JOIN to include bookings even if user/vendor is deleted (showing 'Unknown')
CREATE OR REPLACE VIEW admin_bookings AS
SELECT
    b.id,
    COALESCE(c.name, 'Unknown User') AS user_name,
    COALESCE(v.business_name, 'Unknown Vendor') AS vendor_name,
    b.booking_date,
    b.total_amount AS amount,
    b.status,
    false AS priority, -- Default value as priority column doesn't exist in bookings
    b.created_at
FROM
    bookings b
LEFT JOIN
    customer_user c ON b.customer_id = c.id
LEFT JOIN
    vendor_profiles v ON b.vendor_id = v.id;

-- 5. Grant Permissions to the View
GRANT SELECT ON admin_bookings TO authenticated;
GRANT SELECT ON admin_bookings TO service_role;

-- 6. Apply RLS to the underlying 'bookings' table
ALTER TABLE bookings ENABLE ROW LEVEL SECURITY;

-- Reset policies
DROP POLICY IF EXISTS "Admins can view all bookings" ON bookings;
DROP POLICY IF EXISTS "Vendors can view own bookings" ON bookings;
DROP POLICY IF EXISTS "Customers can view own bookings" ON bookings;

-- Create robust policies
CREATE POLICY "Admins can view all bookings" ON bookings
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM admin_user WHERE id = auth.uid()) OR
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'super_admin')
    );

CREATE POLICY "Vendors can view own bookings" ON bookings
    FOR SELECT USING (
        vendor_id IN (SELECT id FROM vendor_profiles WHERE user_id = auth.uid())
    );

CREATE POLICY "Customers can view own bookings" ON bookings
    FOR SELECT USING (
        auth.uid() = customer_id
    );

-- 7. Verification: Return count of rows in the new view
SELECT count(*) as admin_bookings_count FROM admin_bookings;
