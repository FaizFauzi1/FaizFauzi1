-- =====================================================
-- COMPLETE ROW LEVEL SECURITY (RLS) POLICIES
-- EventEase Application - All Tables
-- =====================================================

-- This script sets up comprehensive RLS policies to ensure:
-- 1. Vendors can only access their own data
-- 2. Customers can view approved vendors and manage their own data
-- 3. Admins have full access to everything

-- =====================================================
-- ENABLE RLS ON ALL TABLES
-- =====================================================

ALTER TABLE users ENABLE ROW LEVEL SECURITY;
ALTER TABLE admin_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE customer_user ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE vendor_analytics ENABLE ROW LEVEL SECURITY;

-- =====================================================
-- DROP EXISTING POLICIES (Clean slate)
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
-- USERS TABLE POLICIES
-- =====================================================

-- Users can view their own record
CREATE POLICY "Users can view their own record" ON users
    FOR SELECT USING (auth.uid() = id);

-- Users can update their own record
CREATE POLICY "Users can update their own record" ON users
    FOR UPDATE USING (auth.uid() = id);

-- Admins can view all users
CREATE POLICY "Admins can view all users" ON users
    FOR SELECT USING (
        -- Check role in users table, not admin_user table
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'super_admin')
    );

-- =====================================================
-- ADMIN_USER TABLE POLICIES
-- =====================================================

-- Admins can view all admin users
CREATE POLICY "Admins can view all admin users" ON admin_user
    FOR SELECT USING (
        -- Check role in users table
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'super_admin')
    );

-- Admins can manage admin users
CREATE POLICY "Admins can manage admin users" ON admin_user
    FOR ALL USING (
        -- Check role in users table
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'super_admin')
    );

-- =====================================================
-- VENDOR_USER TABLE POLICIES
-- =====================================================

-- Vendors can view their own record
CREATE POLICY "Vendors can view their own record" ON vendor_user
    FOR SELECT USING (auth.uid() = id);

-- Vendors can update their own record
CREATE POLICY "Vendors can update their own record" ON vendor_user
    FOR UPDATE USING (auth.uid() = id);

-- Admins can view all vendors
CREATE POLICY "Admins can view all vendors" ON vendor_user
    FOR ALL USING (
        -- Check role in users table
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'super_admin')
    );

-- =====================================================
-- CUSTOMER_USER TABLE POLICIES
-- =====================================================

-- Customers can view their own record
CREATE POLICY "Customers can view their own record" ON customer_user
    FOR SELECT USING (auth.uid() = id);

-- Customers can update their own record
CREATE POLICY "Customers can update their own record" ON customer_user
    FOR UPDATE USING (auth.uid() = id);

-- Admins can view all customers
CREATE POLICY "Admins can view all customers" ON customer_user
    FOR ALL USING (
        -- Check role in users table
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'super_admin')
    );

-- =====================================================
-- VENDOR_PROFILES TABLE POLICIES (CRITICAL)
-- =====================================================

-- Vendors can view their own profile
CREATE POLICY "Vendors can view their own profile" ON vendor_profiles
    FOR SELECT USING (auth.uid() = user_id);

-- Vendors can update their own profile ONLY
CREATE POLICY "Vendors can update their own profile" ON vendor_profiles
    FOR UPDATE USING (auth.uid() = user_id);

-- Vendors can insert their own profile
CREATE POLICY "Vendors can insert their own profile" ON vendor_profiles
    FOR INSERT WITH CHECK (auth.uid() = user_id);

-- Customers can view APPROVED vendor profiles (for marketplace)
CREATE POLICY "Customers can view approved vendor profiles" ON vendor_profiles
    FOR SELECT USING (
        profile_completion_status = 'approved' AND
        (SELECT role FROM users WHERE id = auth.uid()) = 'customer'
    );

-- Admins can view all vendor profiles
CREATE POLICY "Admins can view all vendor profiles" ON vendor_profiles
    FOR SELECT USING (
        -- Check role in users table
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'super_admin')
    );

-- Admins can manage all vendor profiles
CREATE POLICY "Admins can manage all vendor profiles" ON vendor_profiles
    FOR ALL USING (
        -- Check role in users table
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'super_admin')
    );

-- =====================================================
-- VENDOR_ANALYTICS TABLE POLICIES
-- =====================================================

-- Vendors can view their own analytics ONLY
CREATE POLICY "Vendors can view their own analytics" ON vendor_analytics
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = vendor_analytics.vendor_id
            AND user_id = auth.uid()
        )
    );

-- Admins can view all vendor analytics
CREATE POLICY "Admins can view all vendor analytics" ON vendor_analytics
    FOR SELECT USING (
        -- Check role in users table
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'super_admin')
    );

-- Admins can manage all vendor analytics
CREATE POLICY "Admins can manage all vendor analytics" ON vendor_analytics
    FOR ALL USING (
        -- Check role in users table
        (SELECT role FROM users WHERE id = auth.uid()) IN ('admin', 'super_admin')

    );

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Run these queries to verify RLS is working:

-- 1. Check if RLS is enabled on all tables
-- SELECT tablename, rowsecurity 
-- FROM pg_tables 
-- WHERE schemaname = 'public' 
-- AND tablename IN ('users', 'admin_user', 'vendor_user', 'customer_user', 'vendor_profiles', 'vendor_analytics');

-- 2. List all policies
-- SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual 
-- FROM pg_policies 
-- WHERE schemaname = 'public'
-- ORDER BY tablename, policyname;

-- =====================================================
-- NOTES
-- =====================================================

-- SECURITY MODEL:
-- 
-- ADMIN:
--   - Full access to all tables and all operations
--   - Can view and manage all users, vendors, customers, profiles, analytics
--
-- VENDOR:
--   - Can only view/update their own vendor_user record
--   - Can only view/update their own vendor_profile (WHERE user_id = auth.uid())
--   - Can only view their own analytics
--   - CANNOT access other vendors' data
--
-- CUSTOMER:
--   - Can only view/update their own customer_user record
--   - Can view APPROVED vendor profiles (for browsing/booking)
--   - CANNOT view pending/rejected vendor profiles
--   - CANNOT access vendor analytics or private data
--
-- IMPORTANT: These policies prevent vendors from accessing or modifying
-- other vendors' data, which was the critical security vulnerability.
