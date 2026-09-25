-- ============================================================
-- DEFINITIVE FIX: Vendor RLS using Security Definer
-- ============================================================

-- 1. Create a secure function to get the current user's vendor_id
-- SECURITY DEFINER means this runs with the permissions of the creator (postgres/admin),
-- bypassing RLS on vendor_profiles for the lookup.
CREATE OR REPLACE FUNCTION get_my_vendor_id()
RETURNS UUID AS $$
    SELECT id 
    FROM vendor_profiles 
    WHERE user_id = auth.uid()
    LIMIT 1;
$$ LANGUAGE sql SECURITY DEFINER;

-- 2. Enable RLS on vendor_services (just in case)
ALTER TABLE vendor_services ENABLE ROW LEVEL SECURITY;

-- 3. Clear old failing policies
DROP POLICY IF EXISTS "Vendors can insert their own services" ON vendor_services;
DROP POLICY IF EXISTS "Vendors can update their own services" ON vendor_services;
DROP POLICY IF EXISTS "Vendors can delete their own services" ON vendor_services;
DROP POLICY IF EXISTS "Vendors can view their own services" ON vendor_services; -- Drop if exists

-- 4. Re-create policies using the secure function
-- This is much simpler and less prone to "infinite recursion" or permission errors.

CREATE POLICY "Vendors can insert their own services" ON vendor_services
    FOR INSERT 
    WITH CHECK ( vendor_id = get_my_vendor_id() );

CREATE POLICY "Vendors can update their own services" ON vendor_services
    FOR UPDATE 
    USING ( vendor_id = get_my_vendor_id() );

CREATE POLICY "Vendors can delete their own services" ON vendor_services
    FOR DELETE 
    USING ( vendor_id = get_my_vendor_id() );

CREATE POLICY "Vendors can view their own services" ON vendor_services
    FOR SELECT 
    USING ( vendor_id = get_my_vendor_id() );

-- 5. Ensure Public View Policy exists
DROP POLICY IF EXISTS "Public can view active approved services" ON vendor_services;
CREATE POLICY "Public can view active approved services" ON vendor_services
    FOR SELECT USING (
        service_status = 'active' 
        AND approval_status = 'approved'
        AND is_active = true
    );

-- 6. Helper: Ensure vendor_profiles is readable by owner (for the app to load profile initially)
ALTER TABLE vendor_profiles ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Users can view own vendor profile" ON vendor_profiles;
CREATE POLICY "Users can view own vendor profile" ON vendor_profiles
    FOR SELECT USING (user_id = auth.uid());
