-- ============================================================
-- UPDATE: admin_dashboard_vendors view
-- Adds contact info, legal, and extended profile fields
-- so admin "View Details" shows full vendor information.
-- ============================================================

-- Drop first to allow column reordering
DROP VIEW IF EXISTS admin_dashboard_vendors;

CREATE VIEW admin_dashboard_vendors AS
SELECT 
    vp.id,
    vp.business_name as name,
    COALESCE(
        (CASE WHEN vp.categories IS NOT NULL AND jsonb_typeof(vp.categories::jsonb) = 'array'
              THEN (vp.categories::jsonb -> 0)::text
              ELSE vp.categories::text
         END),
        'General'
    ) as category,
    (vp.profile_completion_status = 'approved') as verified,
    (vu.status = 'suspended') as suspended,
    COALESCE(vp.profile_completion_percentage / 20.0, 0.0) as rating,
    0 as reviews,
    0 as bookings,
    (vp.profile_completion_status = 'pending_review') as pending_approval,
    vp.created_at,
    -- Document verification fields
    (vp.profile_completion_status = 'approved') as documents_verified,
    null::text as document_verification_notes,
    null::timestamptz as documents_verified_at,
    COALESCE(vp.email, vu.email) as contact_info,
    -- Extended fields for admin detail view
    vp.categories,
    vp.subcategories,
    vp.coverage_area_state as service_areas,
    COALESCE(vp.phone, vu.phone) as phone,
    COALESCE(vp.email, vu.email) as email,
    COALESCE(vp.operating_address, vp.address) as address,
    vp.ssm_number,
    vp.legal_business_name as legal_name,
    vp.business_type,
    vp.starting_price,
    vp.profile_completion_percentage as completion_percentage,
    COALESCE(vp.priority_score, 0.0) as priority_score,
    vp.subscription_tier,
    vp.subscription_expiry,
    vp.is_claimed,
    vp.claim_code
FROM vendor_profiles vp
LEFT JOIN vendor_user vu ON vp.user_id = vu.id;

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
