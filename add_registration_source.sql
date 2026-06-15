-- Add registration_source column to vendor_profiles
-- Values: 'admin' (created by admin), 'self' (registered via website/app)

ALTER TABLE vendor_profiles 
ADD COLUMN IF NOT EXISTS registration_source TEXT DEFAULT 'self';

-- Update existing unclaimed vendors to 'admin'
UPDATE vendor_profiles 
SET registration_source = 'admin' 
WHERE is_claimed = FALSE OR claim_code IS NOT NULL;

-- Update the admin_dashboard_vendors view to include this column
DROP VIEW IF EXISTS admin_dashboard_vendors;
CREATE VIEW admin_dashboard_vendors AS
SELECT 
    vp.id,
    vp.business_name as name,
    COALESCE(
        CASE 
            WHEN vp.categories IS NULL THEN 'General'
            WHEN vp.categories::text LIKE '[%' THEN (vp.categories::jsonb ->> 0)
            ELSE vp.categories::text
        END, 
        'General'
    ) as category,
    (vp.profile_completion_status = 'approved') as verified,
    (vu.status = 'suspended') as suspended,
    COALESCE(vp.profile_completion_percentage / 20.0, 0.0) as rating,
    0 as reviews,
    0 as bookings,
    (vp.profile_completion_status = 'pending_review') as pending_approval,
    vp.created_at,
    (vp.profile_completion_status = 'approved') as documents_verified,
    null as document_verification_notes,
    null as documents_verified_at,
    COALESCE(vp.email, vu.email) as contact_info,
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
    vp.priority_score,
    vp.subscription_tier,
    vp.subscription_expiry,
    vp.is_claimed,
    vp.claim_code,
    vp.registration_source
FROM vendor_profiles vp
LEFT JOIN vendor_user vu ON vp.user_id = vu.id;
