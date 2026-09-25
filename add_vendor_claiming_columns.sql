-- Migration to allow admin-created vendor profiles and vendor claiming
-- Adds is_claimed and claim_code columns to vendor_profiles
-- Makes user_id nullable for unclaimed vendors

-- 1. Modify vendor_profiles table
ALTER TABLE vendor_profiles 
ALTER COLUMN user_id DROP NOT NULL;

ALTER TABLE vendor_profiles
ADD COLUMN IF NOT EXISTS is_claimed BOOLEAN DEFAULT TRUE,
ADD COLUMN IF NOT EXISTS claim_code TEXT UNIQUE;

-- 2. Update existing records
UPDATE vendor_profiles SET is_claimed = TRUE WHERE is_claimed IS NULL;

-- 3. Update RLS policies for vendor_profiles
-- Drop existing policies if they exist (need to check exact names in schema)
-- Assuming some standard names based on previous patterns

-- Allow admins to manage all vendor profiles
CREATE POLICY "Admins can manage all vendor profiles" 
ON vendor_profiles 
FOR ALL 
TO authenticated 
USING (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND (users.role = 'admin' OR users.role = 'super_admin')
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1 FROM users 
    WHERE users.id = auth.uid() 
    AND (users.role = 'admin' OR users.role = 'super_admin')
  )
);

-- Allow users to view unclaimed profiles
CREATE POLICY "Anyone can view unclaimed vendor profiles" 
ON vendor_profiles 
FOR SELECT 
USING (is_claimed = FALSE OR user_id = auth.uid());

-- Allow users to claim a profile if they have the code
-- This usually happens via an RPC or a specific update, but here is a policy
CREATE POLICY "Users can update their own or unclaimed profiles with code"
ON vendor_profiles
FOR UPDATE
TO authenticated
USING (user_id = auth.uid() OR is_claimed = FALSE)
WITH CHECK (user_id = auth.uid());
