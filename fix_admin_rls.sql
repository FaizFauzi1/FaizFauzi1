-- =====================================================
-- FIX: Admin RLS Access Issue
-- =====================================================
-- This script fixes the issue where admins can't see vendor data after RLS is enabled

-- First, let's check if the current user is an admin
-- Run this query to debug:
-- SELECT auth.uid(), role FROM users WHERE id = auth.uid();

-- =====================================================
-- OPTION 1: Add Service Role Bypass (Recommended for Development)
-- =====================================================

-- Drop existing vendor_profiles policies
DROP POLICY IF EXISTS "Vendors can view their own profile" ON vendor_profiles;
DROP POLICY IF EXISTS "Vendors can update their own profile" ON vendor_profiles;
DROP POLICY IF EXISTS "Vendors can insert their own profile" ON vendor_profiles;
DROP POLICY IF EXISTS "Customers can view approved vendor profiles" ON vendor_profiles;
DROP POLICY IF EXISTS "Admins can view all vendor profiles" ON vendor_profiles;
DROP POLICY IF EXISTS "Admins can manage all vendor profiles" ON vendor_profiles;

-- Recreate with improved admin detection

-- Service role bypass (for backend operations)
CREATE POLICY "Service role bypass" ON vendor_profiles
    FOR ALL USING (
        auth.jwt() ->> 'role' = 'service_role'
    );

-- Vendors can view their own profile
CREATE POLICY "Vendors can view their own profile" ON vendor_profiles
    FOR SELECT USING (
        auth.uid() = user_id
    );

-- Vendors can update their own profile ONLY
CREATE POLICY "Vendors can update their own profile" ON vendor_profiles
    FOR UPDATE USING (
        auth.uid() = user_id
    );

-- Vendors can insert their own profile
CREATE POLICY "Vendors can insert their own profile" ON vendor_profiles
    FOR INSERT WITH CHECK (
        auth.uid() = user_id
    );

-- Customers can view APPROVED vendor profiles (for marketplace)
CREATE POLICY "Customers can view approved vendor profiles" ON vendor_profiles
    FOR SELECT USING (
        profile_completion_status = 'approved' AND
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role = 'customer'
        )
    );

-- Admins can view all vendor profiles (IMPROVED)
CREATE POLICY "Admins can view all vendor profiles" ON vendor_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

-- Admins can manage all vendor profiles (IMPROVED)
CREATE POLICY "Admins can manage all vendor profiles" ON vendor_profiles
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM users
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
    );

-- =====================================================
-- OPTION 2: Temporarily Disable RLS (For Testing Only)
-- =====================================================

-- Uncomment this line ONLY for testing to disable RLS temporarily
-- ALTER TABLE vendor_profiles DISABLE ROW LEVEL SECURITY;

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Check current user's role
-- SELECT id, email, role FROM users WHERE id = auth.uid();

-- Check if RLS is enabled
-- SELECT tablename, rowsecurity FROM pg_tables WHERE tablename = 'vendor_profiles';

-- List all policies on vendor_profiles
-- SELECT policyname, permissive, roles, cmd FROM pg_policies WHERE tablename = 'vendor_profiles';
