-- EventEase Database Migration
-- Run this after creating the schema to fix existing issues

-- ===========================================
-- FIX EXISTING DATA ISSUES
-- ===========================================

-- Step 1: Ensure all existing auth users have entries in users table
INSERT INTO users (id, email, role)
SELECT
    au.id,
    au.email,
    COALESCE(au.raw_user_meta_data->>'role', 'customer') as role
FROM auth.users au
WHERE NOT EXISTS (
    SELECT 1 FROM users u WHERE u.id = au.id
);

-- Step 2: Ensure all vendor users have vendor_profiles (required for analytics)
INSERT INTO vendor_profiles (user_id, business_name)
SELECT
    vu.id,
    COALESCE(vu.name, 'Business Name') as business_name
FROM vendor_user vu
WHERE NOT EXISTS (
    SELECT 1 FROM vendor_profiles vp WHERE vp.user_id = vu.id
);

-- Step 3: Create missing vendor analytics records
INSERT INTO vendor_analytics (vendor_id, date)
SELECT
    vp.id,
    CURRENT_DATE
FROM vendor_profiles vp
WHERE NOT EXISTS (
    SELECT 1 FROM vendor_analytics va
    WHERE va.vendor_id = vp.id AND va.date = CURRENT_DATE
);

-- Step 4: Update users table with correct roles from role-specific tables
UPDATE users
SET role = 'admin'
WHERE id IN (SELECT id FROM admin_user);

UPDATE users
SET role = 'vendor'
WHERE id IN (SELECT id FROM vendor_user);

UPDATE users
SET role = 'customer'
WHERE id IN (SELECT id FROM customer_user);

-- ===========================================
-- CLEANUP BROKEN REFERENCES
-- ===========================================

-- Remove vendor_analytics records that reference non-existent vendor_profiles
DELETE FROM vendor_analytics
WHERE vendor_id NOT IN (
    SELECT id FROM vendor_profiles
);

-- ===========================================
-- UPDATE TRIGGERS TO BE MORE ROBUST
-- ===========================================

-- Drop and recreate the vendor analytics trigger to be safer
DROP TRIGGER IF EXISTS on_vendor_user_created ON vendor_user;
DROP FUNCTION IF EXISTS create_vendor_analytics();

-- Create a safer version that only runs after vendor_profiles is created
CREATE OR REPLACE FUNCTION create_vendor_analytics()
RETURNS TRIGGER AS $$
DECLARE
    profile_exists BOOLEAN;
BEGIN
    -- Check if vendor_profiles record exists
    SELECT EXISTS(
        SELECT 1 FROM vendor_profiles WHERE user_id = NEW.id
    ) INTO profile_exists;

    -- Only create analytics if profile exists
    IF profile_exists THEN
        INSERT INTO vendor_analytics (vendor_id, date)
        SELECT vp.id, CURRENT_DATE
        FROM vendor_profiles vp
        WHERE vp.user_id = NEW.id
        ON CONFLICT (vendor_id, date) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate the trigger
CREATE TRIGGER on_vendor_user_created
    AFTER INSERT ON vendor_user
    FOR EACH ROW EXECUTE FUNCTION create_vendor_analytics();

-- ===========================================
-- ADD HELPER FUNCTIONS FOR MAINTENANCE
-- ===========================================

-- Function to sync user roles (call this periodically)
CREATE OR REPLACE FUNCTION sync_user_roles()
RETURNS INTEGER AS $$
DECLARE
    updated_count INTEGER := 0;
BEGIN
    -- Update admin roles
    UPDATE users
    SET role = 'admin', updated_at = NOW()
    WHERE id IN (SELECT id FROM admin_user)
    AND role != 'admin';

    GET DIAGNOSTICS updated_count = ROW_COUNT;

    -- Update vendor roles
    UPDATE users
    SET role = 'vendor', updated_at = NOW()
    WHERE id IN (SELECT id FROM vendor_user)
    AND role != 'vendor';

    -- Update customer roles
    UPDATE users
    SET role = 'customer', updated_at = NOW()
    WHERE id IN (SELECT id FROM customer_user)
    AND role != 'customer';

    RETURN updated_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to create missing vendor profiles
CREATE OR REPLACE FUNCTION create_missing_vendor_profiles()
RETURNS INTEGER AS $$
DECLARE
    created_count INTEGER := 0;
BEGIN
    INSERT INTO vendor_profiles (user_id, business_name)
    SELECT
        vu.id,
        COALESCE(vu.name, 'Business Name') as business_name
    FROM vendor_user vu
    WHERE NOT EXISTS (
        SELECT 1 FROM vendor_profiles vp WHERE vp.user_id = vu.id
    );

    GET DIAGNOSTICS created_count = ROW_COUNT;
    RETURN created_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===========================================
-- VERIFICATION QUERIES
-- ===========================================

-- Query to check data consistency
-- SELECT 'Users without role-specific records' as issue,
--        COUNT(*) as count
-- FROM users u
-- WHERE NOT EXISTS (SELECT 1 FROM admin_user WHERE id = u.id)
--   AND NOT EXISTS (SELECT 1 FROM vendor_user WHERE id = u.id)
--   AND NOT EXISTS (SELECT 1 FROM customer_user WHERE id = u.id);

-- Query to check vendor analytics consistency
-- SELECT 'Vendor users without profiles' as issue,
--        COUNT(*) as count
-- FROM vendor_user vu
-- WHERE NOT EXISTS (SELECT 1 FROM vendor_profiles vp WHERE vp.user_id = vu.id);

-- ===========================================
-- SCHEDULED MAINTENANCE (Optional)
-- ===========================================

-- Create a function that can be called by cron or manually
CREATE OR REPLACE FUNCTION daily_maintenance()
RETURNS TEXT AS $$
DECLARE
    result_text TEXT := '';
    synced_roles INTEGER;
    created_profiles INTEGER;
BEGIN
    -- Sync roles
    SELECT sync_user_roles() INTO synced_roles;

    -- Create missing profiles
    SELECT create_missing_vendor_profiles() INTO created_profiles;

    result_text := format('Maintenance completed: %s roles synced, %s profiles created',
                         synced_roles, created_profiles);

    -- Log the maintenance
    RAISE NOTICE '%', result_text;

    RETURN result_text;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
