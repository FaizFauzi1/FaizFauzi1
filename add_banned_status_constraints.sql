-- Migration to add 'banned' status to user tables
-- Run this in your Supabase SQL Editor

-- 1. Update admin_user status constraint
ALTER TABLE admin_user DROP CONSTRAINT IF EXISTS admin_user_status_check;
ALTER TABLE admin_user ADD CONSTRAINT admin_user_status_check CHECK (status IN ('active', 'inactive', 'banned'));

-- 2. Update vendor_user status constraint
ALTER TABLE vendor_user DROP CONSTRAINT IF EXISTS vendor_user_status_check;
ALTER TABLE vendor_user ADD CONSTRAINT vendor_user_status_check CHECK (status IN ('active', 'inactive', 'pending', 'suspended', 'banned'));

-- 3. Update customer_user status constraint
ALTER TABLE customer_user DROP CONSTRAINT IF EXISTS customer_user_status_check;
ALTER TABLE customer_user ADD CONSTRAINT customer_user_status_check CHECK (status IN ('active', 'inactive', 'banned'));

-- 4. Update vendor_services status constraint (optional but recommended)
ALTER TABLE vendor_services DROP CONSTRAINT IF EXISTS vendor_services_status_check;
ALTER TABLE vendor_services ADD CONSTRAINT vendor_services_status_check CHECK (status IN ('active', 'inactive', 'suspended', 'banned'));

-- Log the changes
COMMENT ON TABLE admin_user IS 'Updated status constraint to include banned';
COMMENT ON TABLE vendor_user IS 'Updated status constraint to include banned';
COMMENT ON TABLE customer_user IS 'Updated status constraint to include banned';
