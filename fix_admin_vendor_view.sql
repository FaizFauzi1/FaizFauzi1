-- ============================================================
-- FIX: Create View for Admin Dashboard Vendor List
-- ============================================================

-- The AdminProvider expects a rich view of vendors (admin_vendors), 
-- but the actual schema only has a junction table 'admin_vendors'.
-- We create a new view 'admin_dashboard_vendors' to serve the data.

CREATE OR REPLACE VIEW admin_dashboard_vendors AS
SELECT 
    vp.id,
    vp.business_name as name,
    'General' as category, -- Placeholder: Column missing in schema
    (vp.profile_completion_status = 'approved') as verified,
    (vu.status = 'suspended') as suspended,
    COALESCE(vp.profile_completion_percentage / 20.0, 0.0) as rating, -- Placeholder based on completion
    0 as reviews, -- Placeholder
    0 as bookings, -- Placeholder
    (vp.profile_completion_status = 'pending_review') as pending_approval,
    vp.created_at,
    -- Document verification fields
    (vp.profile_completion_status = 'approved') as documents_verified,
    null as document_verification_notes,
    null as documents_verified_at,
    COALESCE(vp.business_email, vu.email) as contact_info,
    -- Added fields for AdminProvider parity
    vp.categories,
    vp.subcategories,
    vp.coverage_area_state as service_areas,
    COALESCE(vp.business_phone, vu.phone) as phone,
    COALESCE(vp.business_email, vu.email) as email,
    COALESCE(vp.operating_address, vp.business_address) as address,
    vp.ssm_number,
    vp.legal_business_name as legal_name,
    vp.business_type,
    vp.starting_price,
    vp.profile_completion_percentage as completion_percentage,
    vp.priority_score,
    vp.subscription_tier,
    vp.subscription_expiry,
    vp.is_claimed,
    vp.claim_code
FROM vendor_profiles vp
LEFT JOIN vendor_user vu ON vp.user_id = vu.id;

-- Grant access to this view (implicitly relies on underlying tables RLS if not defined usually)
-- But ensuring underlying tables have Admin RLS is key.

-- Ensure Admins can view vendor_profiles
DROP POLICY IF EXISTS "Admins can view all vendor profiles" ON vendor_profiles;
CREATE POLICY "Admins can view all vendor profiles" ON vendor_profiles
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user 
            WHERE id = auth.uid() 
            AND status = 'active'
        )
    );

-- Ensure Admins can view vendor_user
DROP POLICY IF EXISTS "Admins can view all vendor users" ON vendor_user;
CREATE POLICY "Admins can view all vendor users" ON vendor_user
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM admin_user 
            WHERE id = auth.uid() 
            AND status = 'active'
        )
    );

-- Ensure Admins can view admin_dashboard_vendors (matches logic of underlying tables)
-- PostgreSQL views run with permissions of the user usually.
