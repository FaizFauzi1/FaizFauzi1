-- Fix foreign key constraint on admin_notifications table
-- The constraint was likely added manually or by another migration and is too restrictive or points to the wrong table.

DO $$
BEGIN
    -- Drop the constraint if it exists
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'admin_notifications_related_vendor_id_fkey') THEN
        ALTER TABLE public.admin_notifications DROP CONSTRAINT admin_notifications_related_vendor_id_fkey;
    END IF;
END $$;

-- Optionally, add a more appropriate constraint if needed, 
-- but for now, we'll keep it as TEXT to avoid breaking changes if IDs are mismatched.
-- ALTER TABLE public.admin_notifications ADD CONSTRAINT admin_notifications_related_vendor_id_fkey 
-- FOREIGN KEY (related_vendor_id) REFERENCES vendor_profiles(id) ON DELETE SET NULL;
