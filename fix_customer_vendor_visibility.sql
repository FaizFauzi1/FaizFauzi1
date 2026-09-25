-- =====================================================
-- FIX: Customers can't see vendors (RLS too restrictive)
-- =====================================================

-- OPTION 1: Allow customers to see ALL vendors (for development/testing)
-- Use this during development when you want customers to see all vendors

DROP POLICY IF EXISTS "Customers view approved vendors" ON vendor_profiles;

CREATE POLICY "Customers view all vendors" ON vendor_profiles
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'customer')
    );

-- =====================================================
-- OPTION 2: Approve existing vendors so customers can see them
-- =====================================================

-- Update all vendors to 'approved' status
-- UPDATE vendor_profiles SET profile_completion_status = 'approved';

-- =====================================================
-- OPTION 3: Allow customers to see vendors with any status EXCEPT rejected
-- =====================================================

-- DROP POLICY IF EXISTS "Customers view approved vendors" ON vendor_profiles;
-- DROP POLICY IF EXISTS "Customers view all vendors" ON vendor_profiles;

-- CREATE POLICY "Customers view non-rejected vendors" ON vendor_profiles
--     FOR SELECT USING (
--         profile_completion_status != 'rejected' AND
--         EXISTS (SELECT 1 FROM users WHERE users.id = auth.uid() AND users.role = 'customer')
--     );

-- =====================================================
-- VERIFICATION
-- =====================================================

-- Check vendor statuses
SELECT 
    business_name,
    profile_completion_status,
    profile_completion_percentage
FROM vendor_profiles;

-- Test as customer (should now see vendors)
-- SELECT business_name, profile_completion_status FROM vendor_profiles;
