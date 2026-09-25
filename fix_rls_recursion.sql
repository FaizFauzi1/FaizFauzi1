-- =====================================================
-- FIX: Infinite Recursion in RLS Policies
-- =====================================================
-- This fixes the "infinite recursion detected in policy for relation admin_user" error

-- =====================================================
-- STEP 1: Drop ALL existing policies to start fresh
-- =====================================================

-- Users table
DROP POLICY IF EXISTS "Users can view their own record" ON users;
DROP POLICY IF EXISTS "Admins can view all users" ON users;
DROP POLICY IF EXISTS "Users can update their own record" ON users;

-- Admin user table
DROP POLICY IF EXISTS "Admins can view all admin users" ON admin_user;
DROP POLICY IF EXISTS "Admins can manage admin users" ON admin_user;

-- Vendor user table
DROP POLICY IF EXISTS "Vendors can view their own record" ON vendor_user;
DROP POLICY IF EXISTS "Admins can view all vendors" ON vendor_user;
DROP POLICY IF EXISTS "Vendors can update their own record" ON vendor_user;

-- Customer user table
DROP POLICY IF EXISTS "Customers can view their own record" ON customer_user;
DROP POLICY IF EXISTS "Admins can view all customers" ON customer_user;
DROP POLICY IF EXISTS "Customers can update their own record" ON customer_user;

-- Vendor profiles table
DROP POLICY IF EXISTS "Vendors can view their own profile" ON vendor_profiles;
DROP POLICY IF EXISTS "Vendors can update their own profile" ON vendor_profiles;
DROP POLICY IF EXISTS "Vendors can insert their own profile" ON vendor_profiles;
DROP POLICY IF EXISTS "Customers can view approved vendor profiles" ON vendor_profiles;
DROP POLICY IF EXISTS "Admins can view all vendor profiles" ON vendor_profiles;
DROP POLICY IF EXISTS "Admins can manage all vendor profiles" ON vendor_profiles;

-- Vendor analytics table
DROP POLICY IF EXISTS "Vendors can view their own analytics" ON vendor_analytics;
DROP POLICY IF EXISTS "Admins can view all vendor analytics" ON vendor_analytics;
DROP POLICY IF EXISTS "Admins can manage all vendor analytics" ON vendor_analytics;

-- =====================================================
-- STEP 2: Create USERS table policies FIRST (no dependencies)
-- =====================================================

-- Users can view their own record
CREATE POLICY "Users can view their own record" ON users
    FOR SELECT USING (auth.uid() = id);

-- Users can update their own record
CREATE POLICY "Users can update their own record" ON users
    FOR UPDATE USING (auth.uid() = id);

-- =====================================================
-- STEP 3: Create role-specific table policies (simple, no recursion)
-- =====================================================

-- ADMIN_USER: Only admins can access (check users.role directly)
CREATE POLICY "Admin users full access" ON admin_user
    FOR ALL USING (
        auth.uid() = id OR
        EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('admin', 'super_admin'))
    );

-- VENDOR_USER: Vendors can access own record, admins can access all
CREATE POLICY "Vendor users own access" ON vendor_user
    FOR ALL USING (
        auth.uid() = id OR
        EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('admin', 'super_admin'))
    );

-- CUSTOMER_USER: Customers can access own record, admins can access all
CREATE POLICY "Customer users own access" ON customer_user
    FOR ALL USING (
        auth.uid() = id OR
        EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('admin', 'super_admin'))
    );

-- =====================================================
-- STEP 4: VENDOR_PROFILES policies (CRITICAL - prevents vendor cross-access)
-- =====================================================

-- Vendors can ONLY view/edit their own profile
CREATE POLICY "Vendors own profile access" ON vendor_profiles
    FOR ALL USING (
        user_id = auth.uid()
    );

-- Customers can view APPROVED vendors (for marketplace)
CREATE POLICY "Customers view approved vendors" ON vendor_profiles
    FOR SELECT USING (
        profile_completion_status = 'approved' AND
        EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'customer')
    );

-- Admins have full access to all vendor profiles
CREATE POLICY "Admins full vendor access" ON vendor_profiles
    FOR ALL USING (
        EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('admin', 'super_admin'))
    );

-- =====================================================
-- STEP 5: VENDOR_ANALYTICS policies
-- =====================================================

-- Vendors can view their own analytics
CREATE POLICY "Vendors own analytics" ON vendor_analytics
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE vendor_profiles.id = vendor_analytics.vendor_id
            AND vendor_profiles.user_id = auth.uid()
        )
    );

-- Admins can view all analytics
CREATE POLICY "Admins all analytics" ON vendor_analytics
    FOR ALL USING (
        EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role IN ('admin', 'super_admin'))
    );

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Check that policies are created
SELECT tablename, policyname FROM pg_policies WHERE schemaname = 'public' ORDER BY tablename, policyname;

-- Test as vendor (should only see own profile)
-- SELECT * FROM vendor_profiles;

-- Test as admin (should see all profiles)
-- SELECT * FROM vendor_profiles;
