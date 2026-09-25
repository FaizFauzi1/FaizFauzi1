-- Migration script to create the admin_notifications table
CREATE TABLE IF NOT EXISTS public.admin_notifications (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  type TEXT NOT NULL,
  severity TEXT NOT NULL,
  title TEXT NOT NULL,
  message TEXT NOT NULL,
  related_user_id TEXT,
  related_vendor_id TEXT,
  related_booking_id TEXT,
  status TEXT NOT NULL DEFAULT 'unread',
  action_url TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Enable Row Level Security
ALTER TABLE public.admin_notifications ENABLE ROW LEVEL SECURITY;

-- Create policies for admin_notifications
-- Allow inserts from authenticated users (e.g., when a booking is created or payment fails)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Enable insert for authenticated users' AND tablename = 'admin_notifications') THEN
        CREATE POLICY "Enable insert for authenticated users" 
        ON public.admin_notifications FOR INSERT 
        TO authenticated 
        WITH CHECK (true);
    END IF;
END $$;

-- Allow admins to read all notifications 
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Enable read for all users' AND tablename = 'admin_notifications') THEN
        CREATE POLICY "Enable read for all users" 
        ON public.admin_notifications FOR SELECT 
        USING (true);
    END IF;
END $$;

-- Allow updates (like marking as read)
DO $$
BEGIN
    IF NOT EXISTS (SELECT 1 FROM pg_policies WHERE policyname = 'Enable update for all users' AND tablename = 'admin_notifications') THEN
        CREATE POLICY "Enable update for all users" 
        ON public.admin_notifications FOR UPDATE 
        USING (true);
    END IF;
END $$;
