-- ============================================================
-- UPDATE: Enable Draft/Workflow statuses on existing table
-- ============================================================

-- 1. DROP the restrictive check constraint on 'status'
ALTER TABLE vendor_services DROP CONSTRAINT IF EXISTS vendor_services_status_check;

-- 2. ADD new check constraint with Expanded statuses
-- Mapping:
-- Draft -> 'draft'
-- Reviewing -> 'active' + approval_status='pending'
-- Live -> 'active' + approval_status='approved'
-- Offline -> 'inactive'
ALTER TABLE vendor_services ADD CONSTRAINT vendor_services_status_check 
CHECK (status IN ('active', 'inactive', 'suspended', 'draft', 'maintenance', 'discontinued'));

-- 3. Ensure 'approval_status' constraint is correct (User's look fine: pending, approved, rejected)
-- If you need to re-verify:
-- ALTER TABLE vendor_services DROP CONSTRAINT IF EXISTS vendor_services_approval_status_check;
-- ALTER TABLE vendor_services ADD CONSTRAINT vendor_services_approval_status_check 
-- CHECK (approval_status IN ('pending', 'approved', 'rejected'));

-- 4. Enable RLS (if not already on)
ALTER TABLE vendor_services ENABLE ROW LEVEL SECURITY;

-- 5. Add Policies (Safe to run if they don't exist, using DO block or dropping first)

DROP POLICY IF EXISTS "Public can view active approved services" ON vendor_services;
CREATE POLICY "Public can view active approved services" ON vendor_services
    FOR SELECT USING (
        status = 'active' 
        AND approval_status = 'approved'
        AND active = true
    );

DROP POLICY IF EXISTS "Vendors can manage their own services" ON vendor_services;
CREATE POLICY "Vendors can manage their own services" ON vendor_services
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM vendor_profiles
            WHERE id = vendor_services.vendor_id
            AND user_id = auth.uid()
        )
    );

DROP POLICY IF EXISTS "Admins can manage all services" ON vendor_services;
CREATE POLICY "Admins can manage all services" ON vendor_services
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM admin_user
            WHERE id = auth.uid()
            AND status = 'active'
        )
    );
