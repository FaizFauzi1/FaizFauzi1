-- ============================================================
-- FIX: Vendor Services RLS Policy and Column Types
-- ============================================================

-- 0. FIX Column Types if needed (User reported text = boolean mismatch)
DO $$
BEGIN
    -- Check if is_active is TEXT, if so, convert to BOOLEAN
    IF EXISTS (
        SELECT 1 
        FROM information_schema.columns 
        WHERE table_name = 'vendor_services' 
        AND column_name = 'is_active' 
        AND data_type = 'text'
    ) THEN
        ALTER TABLE vendor_services 
        ALTER COLUMN is_active TYPE BOOLEAN 
        USING (is_active::boolean);
    END IF;

    -- Ensure service_status exists, default to 'draft' if missing
    -- (No change needed usually, just precaution)
END $$;

-- 1. Ensure vendor_profiles has RLS enabled and a policy for users to view their OWN profile
ALTER TABLE vendor_profiles ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can view own vendor profile" ON vendor_profiles;
CREATE POLICY "Users can view own vendor profile" ON vendor_profiles
    FOR SELECT USING (user_id = auth.uid());

-- 2. Update vendor_services policies to be more explicit and referencing correct permissions

ALTER TABLE vendor_services ENABLE ROW LEVEL SECURITY;

-- Drop existing overlapping policies to avoid confusion
DROP POLICY IF EXISTS "Vendors can manage their own services" ON vendor_services;
DROP POLICY IF EXISTS "Vendors can insert their own services" ON vendor_services;
DROP POLICY IF EXISTS "Vendors can update their own services" ON vendor_services;
DROP POLICY IF EXISTS "Vendors can delete their own services" ON vendor_services;
DROP POLICY IF EXISTS "Vendors can view their own services" ON vendor_services;

-- INSERT Policy
CREATE POLICY "Vendors can insert their own services" ON vendor_services
    FOR INSERT WITH CHECK (
        vendor_id IN (
            SELECT id FROM vendor_profiles 
            WHERE user_id = auth.uid()
        )
    );

-- UPDATE Policy
CREATE POLICY "Vendors can update their own services" ON vendor_services
    FOR UPDATE USING (
        vendor_id IN (
            SELECT id FROM vendor_profiles 
            WHERE user_id = auth.uid()
        )
    ) WITH CHECK (
        vendor_id IN (
            SELECT id FROM vendor_profiles 
            WHERE user_id = auth.uid()
        )
    );

-- DELETE Policy
CREATE POLICY "Vendors can delete their own services" ON vendor_services
    FOR DELETE USING (
        vendor_id IN (
            SELECT id FROM vendor_profiles 
            WHERE user_id = auth.uid()
        )
    );

-- SELECT Policy (View own services)
CREATE POLICY "Vendors can view their own services" ON vendor_services
    FOR SELECT USING (
        vendor_id IN (
            SELECT id FROM vendor_profiles 
            WHERE user_id = auth.uid()
        )
    );

-- Keep existing "Public can view active approved services" policy
DROP POLICY IF EXISTS "Public can view active approved services" ON vendor_services;
CREATE POLICY "Public can view active approved services" ON vendor_services
    FOR SELECT USING (
        service_status = 'active' 
        AND approval_status = 'approved'
        AND is_active = true
    );
