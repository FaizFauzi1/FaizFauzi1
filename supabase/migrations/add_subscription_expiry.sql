-- Add subscription columns to vendor_profiles
ALTER TABLE vendor_profiles ADD COLUMN IF NOT EXISTS subscription_expiry TIMESTAMP WITH TIME ZONE;
ALTER TABLE vendor_profiles ADD COLUMN IF NOT EXISTS subscription_tier TEXT DEFAULT 'starter';

-- Drop the view first to allow changing the column structure
DROP VIEW IF EXISTS admin_dashboard_vendors;

-- Recreate the admin_dashboard_vendors view to include these columns
CREATE VIEW admin_dashboard_vendors AS
SELECT 
    vp.id,
    vp.business_name as name,
    'General' as category, -- Placeholder: Column missing in schema
    (vp.profile_completion_status = 'approved') as verified,
    (vu.status = 'suspended') as suspended,
    COALESCE(vp.profile_completion_percentage / 20.0, 0.0) as rating, -- Placeholder based on completion
    0 as reviews, -- Placeholder
    0 as bookings, -- Placeholder
    ARRAY[]::text[] as service_areas, -- Placeholder
    (vp.profile_completion_status = 'pending_review') as pending_approval,
    vp.created_at,
    -- Subscription info
    vp.subscription_expiry,
    vp.subscription_tier,
    -- Document verification fields
    (vp.profile_completion_status = 'approved') as documents_verified,
    null as document_verification_notes,
    null as documents_verified_at,
    vu.email as contact_info
FROM vendor_profiles vp
LEFT JOIN vendor_user vu ON vp.user_id = vu.id;

-- Ensure permissions are maintained if needed (usually public views don't need explicit grants in local dev)
-- If there were specific grants, they should be reapplied here.
