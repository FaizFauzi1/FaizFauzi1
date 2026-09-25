-- ============================================================
-- FINAL FIX: Apply Secure RLS Policies
-- ============================================================

-- Since you confirmed you HAVE a Vendor Profile, we just need to 
-- ensure the database uses the correct "Secure Lookup" to find it.

-- 1. Create the Secure Lookup Function
-- (SECURITY DEFINER allows it to read vendor_profiles without restriction)
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

-- 2. Grant Permissions
GRANT EXECUTE ON FUNCTION get_my_vendor_id() TO authenticated;
GRANT EXECUTE ON FUNCTION get_my_vendor_id() TO service_role;

-- 3. Enable RLS
ALTER TABLE vendor_services ENABLE ROW LEVEL SECURITY;

-- 4. Re-Apply Policies using the Secure Function

-- INSERT
DROP POLICY IF EXISTS "Vendors can insert their own services" ON vendor_services;
CREATE POLICY "Vendors can insert their own services" ON vendor_services
    FOR INSERT 
    WITH CHECK ( vendor_id = get_my_vendor_id() );

-- UPDATE
DROP POLICY IF EXISTS "Vendors can update their own services" ON vendor_services;
CREATE POLICY "Vendors can update their own services" ON vendor_services
    FOR UPDATE 
    USING ( vendor_id = get_my_vendor_id() );

-- DELETE
DROP POLICY IF EXISTS "Vendors can delete their own services" ON vendor_services;
CREATE POLICY "Vendors can delete their own services" ON vendor_services
    FOR DELETE 
    USING ( vendor_id = get_my_vendor_id() );

-- SELECT (View Own)
DROP POLICY IF EXISTS "Vendors can view their own services" ON vendor_services;
CREATE POLICY "Vendors can view their own services" ON vendor_services
    FOR SELECT 
    USING ( vendor_id = get_my_vendor_id() );

-- PUBLIC VIEW (Keep existing)
DROP POLICY IF EXISTS "Public can view active approved services" ON vendor_services;
CREATE POLICY "Public can view active approved services" ON vendor_services
    FOR SELECT USING (
        service_status = 'active' 
        AND approval_status = 'approved'
        AND is_active = true
    );
