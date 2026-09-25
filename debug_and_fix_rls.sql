-- ============================================================
-- DEBUG & FIX: RLS Permissions
-- ============================================================

-- 1. Robust Security Definer Function
-- explicitly setting search_path to 'public' to avoid hijacking
CREATE OR REPLACE FUNCTION get_my_vendor_id()
RETURNS UUID 
LANGUAGE sql 
SECURITY DEFINER 
SET search_path = public
AS $$
    SELECT id 
    FROM vendor_profiles 
    WHERE user_id = auth.uid()
    LIMIT 1;
$$;

-- Grant execution to everyone (authenticated users need this)
GRANT EXECUTE ON FUNCTION get_my_vendor_id() TO authenticated;
GRANT EXECUTE ON FUNCTION get_my_vendor_id() TO service_role;

-- 2. Re-Apply Policies on vendor_services
ALTER TABLE vendor_services ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Vendors can insert their own services" ON vendor_services;
CREATE POLICY "Vendors can insert their own services" ON vendor_services
    FOR INSERT 
    WITH CHECK ( vendor_id = get_my_vendor_id() );

DROP POLICY IF EXISTS "Vendors can update their own services" ON vendor_services;
CREATE POLICY "Vendors can update their own services" ON vendor_services
    FOR UPDATE 
    USING ( vendor_id = get_my_vendor_id() );

DROP POLICY IF EXISTS "Vendors can delete their own services" ON vendor_services;
CREATE POLICY "Vendors can delete their own services" ON vendor_services
    FOR DELETE 
    USING ( vendor_id = get_my_vendor_id() );

DROP POLICY IF EXISTS "Vendors can view their own services" ON vendor_services;
CREATE POLICY "Vendors can view their own services" ON vendor_services
    FOR SELECT 
    USING ( vendor_id = get_my_vendor_id() );

-- 3. DEBUG: Run this to verify YOU have a vendor profile
-- This will return your User ID and Vendor ID (if found).
-- If Vendor ID is NULL, that is why the Insert fails.
SELECT 
    auth.uid() as my_user_id, 
    get_my_vendor_id() as my_vendor_id;
