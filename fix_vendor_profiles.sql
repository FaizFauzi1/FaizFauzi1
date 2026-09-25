-- Fix for vendor profiles not being created
-- Run this script in your Supabase SQL editor

-- First, check the current table structure
SELECT column_name FROM information_schema.columns
WHERE table_name = 'vendor_profiles' ORDER BY ordinal_position;

-- Update the trigger function to match the actual table structure
CREATE OR REPLACE FUNCTION create_vendor_profile()
RETURNS TRIGGER AS $$
DECLARE
    user_meta jsonb;
BEGIN
    -- Get user metadata from auth.users
    SELECT raw_user_meta_data INTO user_meta
    FROM auth.users
    WHERE id = NEW.id;

    -- Create basic vendor profile when vendor_user is created
    -- Use dynamic SQL to handle different table structures
    BEGIN
        EXECUTE format('INSERT INTO vendor_profiles (user_id, business_name) VALUES ($1, $2) ON CONFLICT (user_id) DO NOTHING')
        USING NEW.id, COALESCE(user_meta->>'business_name', COALESCE(NEW.name, 'Business Name'));
    EXCEPTION WHEN OTHERS THEN
        -- Log and continue; do not abort the creating of the auth user
        RAISE NOTICE 'create_vendor_profile: vendor_profiles insert failed: %', SQLERRM;
    END;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Create missing vendor profiles for existing vendor_user records
-- Use a safer approach that only inserts required fields
INSERT INTO vendor_profiles (user_id, business_name)
SELECT
    vu.id,
    COALESCE(au.raw_user_meta_data->>'business_name', COALESCE(vu.name, 'Business Name'))
FROM vendor_user vu
LEFT JOIN vendor_profiles vp ON vu.id = vp.user_id
LEFT JOIN auth.users au ON vu.id = au.id
WHERE vp.user_id IS NULL; -- Only create profiles for vendors that don't have one

-- Create missing vendor analytics for the newly created profiles
INSERT INTO vendor_analytics (vendor_id, date)
SELECT vp.id, CURRENT_DATE
FROM vendor_profiles vp
LEFT JOIN vendor_analytics va ON vp.id = va.vendor_id
WHERE va.vendor_id IS NULL
ON CONFLICT (vendor_id, date) DO NOTHING;

-- Verify the fix
SELECT
    'vendor_user_count' as metric,
    COUNT(*) as count
FROM vendor_user
UNION ALL
SELECT
    'vendor_profiles_count' as metric,
    COUNT(*) as count
FROM vendor_profiles
UNION ALL
SELECT
    'vendor_analytics_count' as metric,
    COUNT(*) as count
FROM vendor_analytics;
