-- Fix Admin Permissions for Vendor Approval

-- 1. Grant usage on schema (usually default, but good to ensure)
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;

-- 2. Ensure Admins can UPDATE vendor_profiles
DROP POLICY IF EXISTS "Admins can update vendor profiles" ON vendor_profiles;
CREATE POLICY "Admins can update vendor profiles" ON vendor_profiles
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM admin_user 
            WHERE id = auth.uid() 
            -- AND status = 'active' -- Optional: strict check
        )
    );

-- 3. Ensure Admins can UPDATE vendor_user (to set status to active)
DROP POLICY IF EXISTS "Admins can update vendor_user" ON vendor_user;
CREATE POLICY "Admins can update vendor_user" ON vendor_user
    FOR UPDATE USING (
        EXISTS (
            SELECT 1 FROM admin_user 
            WHERE id = auth.uid()
        )
    );

-- 4. Ensure Admins can SELECT vendor_user (needed for finding user to update)
DROP POLICY IF EXISTS "Admins can view all vendor users" ON vendor_user;
CREATE POLICY "Admins can view all vendor users" ON vendor_user
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user 
            WHERE id = auth.uid()
        )
    );

-- 5. Refresh Admin Vendor View Permissions (explicitly)
GRANT SELECT ON admin_dashboard_vendors TO authenticated, service_role;
