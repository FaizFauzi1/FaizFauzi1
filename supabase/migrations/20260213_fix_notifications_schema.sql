-- Fix Notifications Schema & Foreign Key Constraint
-- Run this in your Supabase SQL Editor

-- 1. Correct the Foreign Key Constraint for Notifications
-- We first drop any existing constraint to ensure we can point it to auth.users
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'notifications_user_id_fkey') THEN
        ALTER TABLE public.notifications DROP CONSTRAINT notifications_user_id_fkey;
    END IF;
END $$;

ALTER TABLE public.notifications
ADD CONSTRAINT notifications_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- 2. Correct the Foreign Key Constraint for Notification Settings
DO $$ 
BEGIN
    IF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'notification_settings_user_id_fkey') THEN
        ALTER TABLE public.notification_settings DROP CONSTRAINT notification_settings_user_id_fkey;
    ELSIF EXISTS (SELECT 1 FROM pg_constraint WHERE conname = 'notification_settings_pkey') THEN
        -- If it's a primary key constraint acting as a reference, we might need to handle it differently
        -- But usually it's a separate FK.
        NULL;
    END IF;
END $$;

-- Ensure notification_settings points to auth.users as well
ALTER TABLE public.notification_settings
DROP CONSTRAINT IF EXISTS notification_settings_user_id_fkey;

ALTER TABLE public.notification_settings
ADD CONSTRAINT notification_settings_user_id_fkey 
FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

-- 3. Ensure all columns exist (from previous migration)
ALTER TABLE public.notifications 
ADD COLUMN IF NOT EXISTS severity TEXT DEFAULT 'info',
ADD COLUMN IF NOT EXISTS channel TEXT DEFAULT 'inapp',
ADD COLUMN IF NOT EXISTS notification_status TEXT DEFAULT 'delivered',
ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS scheduled_for TIMESTAMP WITH TIME ZONE,
ADD COLUMN IF NOT EXISTS action_url TEXT,
ADD COLUMN IF NOT EXISTS image_url TEXT;

-- 4. Enable RLS and add policies (Double ensuring)
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

DO $$ 
BEGIN
    -- Drop existing to avoid conflicts during update
    DROP POLICY IF EXISTS "Users can view own notifications" ON public.notifications;
    DROP POLICY IF EXISTS "Users can update own notifications" ON public.notifications;
    DROP POLICY IF EXISTS "System can insert notifications" ON public.notifications;
    
    CREATE POLICY "Users can view own notifications" ON public.notifications 
        FOR SELECT USING (auth.uid() = user_id);
    
    CREATE POLICY "Users can update own notifications" ON public.notifications 
        FOR UPDATE USING (auth.uid() = user_id);
    
    CREATE POLICY "System can insert notifications" ON public.notifications 
        FOR INSERT WITH CHECK (true);
END $$;
