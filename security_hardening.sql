-- ===========================================
-- SECURITY HARDENING POLICIES (RLS)
-- ===========================================
-- This script applies stricter security rules to prevent unauthorized access and data manipulation.

-- 0. ADMIN CHECK FUNCTION (To prevent infinite recursion)
-- This function runs with SECURITY DEFINER, allowing it to bypass RLS on admin_user.
CREATE OR REPLACE FUNCTION is_admin_check(check_id uuid) 
RETURNS boolean AS $$
BEGIN
  RETURN EXISTS (SELECT 1 FROM admin_user WHERE id = check_id);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 1. USERS TABLE HARDENING
-- Only allow users to view their own basic info.
-- Only admins can see all users.
-- Prevent users from updating their own ROLE or STATUS.

DROP POLICY IF EXISTS "Users can view their own record" ON users;
CREATE POLICY "Users can view their own record" ON users
    FOR SELECT USING (auth.uid() = id OR is_admin_check(auth.uid()));

DROP POLICY IF EXISTS "Users can update their own non-sensitive fields" ON users;
-- NOTE: In a real app, you'd use a service role or a specific function to update roles.
-- This policy allows users to update nothing by default via the client side to be safe.
-- If they need to update profile, they should do it in customer_user/vendor_user tables.

-- 2. ROLE-SPECIFIC TABLE HARDENING
-- customer_user
ALTER TABLE customer_user ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Customers can manage their own profile" ON customer_user;
CREATE POLICY "Customers can manage their own profile" ON customer_user
    FOR ALL USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admins can view all customers" ON customer_user;
CREATE POLICY "Admins can view all customers" ON customer_user
    FOR SELECT USING (is_admin_check(auth.uid()));

-- vendor_user
ALTER TABLE vendor_user ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Vendors can manage their own profile" ON vendor_user;
CREATE POLICY "Vendors can manage their own profile" ON vendor_user
    FOR ALL USING (auth.uid() = id);

DROP POLICY IF EXISTS "Admins can view all vendors" ON vendor_user;
CREATE POLICY "Admins can view all vendors" ON vendor_user
    FOR SELECT USING (is_admin_check(auth.uid()));

-- 3. PREVENT UNAUTHORIZED ROLE ESCALATION
-- Users should never be able to insert into admin_user table.
ALTER TABLE admin_user ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can manage admin list" ON admin_user;
CREATE POLICY "Admins can manage admin list" ON admin_user
    FOR ALL USING (
        -- Only if the current user is already an admin
        -- Use is_admin_check to avoid recursion
        is_admin_check(auth.uid())
    );

-- 4. BOOKINGS PROTECTION
-- Ensure users can only see their own bookings and vendors can only see bookings for their services.
DROP POLICY IF EXISTS "Users can view their own bookings" ON bookings;
CREATE POLICY "Users can view their own bookings" ON bookings
    FOR SELECT USING (
        auth.uid() = customer_id OR 
        EXISTS (
            SELECT 1 FROM vendor_profiles 
            WHERE id = bookings.vendor_id AND user_id = auth.uid()
        )
    );

-- 5. REVIEWS PROTECTION
-- Only allow users who HAD a booking to leave a review.
DROP POLICY IF EXISTS "Customers can leave reviews for their bookings" ON reviews;
CREATE POLICY "Customers can leave reviews for their bookings" ON reviews
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM bookings
            WHERE id = reviews.booking_id
            AND customer_id = auth.uid()
            AND status = 'completed'
        )
    );

-- 6. GENERAL INPUT SANITIZATION (CONCEPTUAL)
-- Supabase handles SQL injection by using parameterized queries via PostgREST.
-- We ensure that all "Update" and "Delete" actions are physically gated by auth.uid().

COMMIT;
