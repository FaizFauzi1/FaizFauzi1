-- Fix vendor_users reference issue
-- This script finds and fixes any references to 'vendor_users' (plural) 
-- which should be 'vendor_user' (singular)

-- First, let's check if there are any functions or triggers referencing vendor_users
-- Run this query to find problematic functions:
SELECT 
    n.nspname as schema_name,
    p.proname as function_name,
    pg_get_functiondef(p.oid) as function_definition
FROM pg_proc p
JOIN pg_namespace n ON p.pronamespace = n.oid
WHERE pg_get_functiondef(p.oid) ILIKE '%vendor_users%'
AND n.nspname = 'public';

-- Check for triggers
SELECT 
    t.tgname as trigger_name,
    c.relname as table_name,
    pg_get_triggerdef(t.oid) as trigger_definition
FROM pg_trigger t
JOIN pg_class c ON t.tgrelid = c.oid
WHERE pg_get_triggerdef(t.oid) ILIKE '%vendor_users%';

-- Check for views
SELECT 
    schemaname,
    viewname,
    definition
FROM pg_views
WHERE definition ILIKE '%vendor_users%'
AND schemaname = 'public';

-- Drop and recreate the admin_dashboard_vendors view if it exists with wrong reference
DROP VIEW IF EXISTS admin_dashboard_vendors CASCADE;

CREATE OR REPLACE VIEW admin_dashboard_vendors AS
SELECT 
    vp.id,
    vp.user_id,
    vp.business_name as name,
    COALESCE(
        CASE 
            WHEN jsonb_typeof(vp.categories) = 'array' THEN vp.categories->>0
            ELSE vp.categories::text
        END,
        'Vendor'
    ) as category,
    CASE 
        WHEN vp.profile_completion_status = 'approved' THEN true
        ELSE false
    END as verified,
    CASE 
        WHEN vu.status = 'suspended' THEN true
        ELSE false
    END as suspended,
    0.0 as rating,
    0 as reviews,
    0 as bookings,
    COALESCE(vp.service_areas, '[]'::jsonb) as service_areas,
    CASE 
        WHEN vp.profile_completion_status = 'pending_review' THEN true
        ELSE false
    END as pending_approval,
    false as documents_verified,
    NULL as document_verification_notes,
    NULL as documents_verified_at,
    vp.created_at,
    vp.updated_at
FROM vendor_profiles vp
LEFT JOIN vendor_user vu ON vp.user_id = vu.id;  -- Changed from vendor_users to vendor_user

-- Grant access to the view
GRANT SELECT ON admin_dashboard_vendors TO authenticated;
GRANT SELECT ON admin_dashboard_vendors TO anon;

-- Ensure RLS policies use correct table name
-- Drop any existing policies that might have wrong references
DO $$ 
BEGIN
    -- This will help identify if there are any policies with vendor_users reference
    -- You may need to manually fix specific policies based on the output
    NULL;
END $$;

COMMENT ON VIEW admin_dashboard_vendors IS 'Admin dashboard view of all vendors from vendor_profiles table';
