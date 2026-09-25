-- =====================================================
-- DIAGNOSTIC QUERIES - Run these in Supabase SQL Editor
-- =====================================================

-- 1. Check if you're logged in and what your role is
SELECT 
    auth.uid() as current_user_id,
    u.email,
    u.role
FROM users u
WHERE u.id = auth.uid();

-- 2. Check all users and their roles
SELECT id, email, role FROM users;

-- 3. Check if admin_user table has any records
SELECT * FROM admin_user;

-- 4. Check vendor_profiles without RLS (as service role)
SELECT 
    vp.id,
    vp.user_id,
    vp.business_name,
    u.email,
    u.role
FROM vendor_profiles vp
LEFT JOIN users u ON u.id = vp.user_id;

-- 5. Check current RLS policies on vendor_profiles
SELECT 
    schemaname,
    tablename,
    policyname,
    permissive,
    roles,
    cmd,
    qual
FROM pg_policies 
WHERE tablename = 'vendor_profiles'
ORDER BY policyname;

-- 6. Test if RLS is blocking you
-- This should return rows if you're an admin
SELECT COUNT(*) as vendor_count FROM vendor_profiles;

-- =====================================================
-- QUICK FIX: If admin can't see vendors
-- =====================================================

-- Option A: Temporarily disable RLS to test (NOT for production)
-- ALTER TABLE vendor_profiles DISABLE ROW LEVEL SECURITY;

-- Option B: Check if your user has the admin role in users table
-- If not, update it:
-- UPDATE users SET role = 'admin' WHERE email = 'your-admin-email@example.com';

-- Option C: Add yourself to admin_user table if missing
-- INSERT INTO admin_user (id, name, email, role)
-- SELECT id, 'Admin User', email, 'admin'
-- FROM users
-- WHERE email = 'your-admin-email@example.com'
-- ON CONFLICT (id) DO NOTHING;
