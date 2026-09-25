-- ============================================================
-- FIX: Create Vendor Profile (Manual Mode)
-- ============================================================

-- STEP 1: Run this line first to find your User ID (UUID)
-- Look for your email address and copy the 'id'.
SELECT id, email, last_sign_in_at 
FROM auth.users 
ORDER BY last_sign_in_at DESC 
LIMIT 10;

-- STEP 2: Replace 'PASTE_YOUR_UUID_HERE' below with the ID you copied.
-- Then select these lines and run them.

INSERT INTO vendor_profiles (
    user_id, 
    business_name, 
    description,
    email,
    profile_completion_status,
    created_at,
    updated_at
)
VALUES (
    'PASTE_YOUR_UUID_HERE',  -- <--- PASTE IT HERE (keep the quotes!)
    'My Manual Vendor Business',
    'Manually created vendor profile',
    'myemail@example.com',   -- You can update this to your real email if you want
    'completed',
    NOW(),
    NOW()
);

-- STEP 3: Verify it worked
-- SELECT * FROM vendor_profiles WHERE user_id = 'PASTE_YOUR_UUID_HERE';
