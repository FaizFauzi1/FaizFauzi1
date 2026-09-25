-- Create tables for Admin Dashboard dynamic data

-- Admin Activity Log
CREATE TABLE IF NOT EXISTS public.admin_activity_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    subtitle TEXT,
    activity_type TEXT NOT NULL, -- 'registration', 'payment', 'dispute', 'system'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE public.admin_activity_log ENABLE ROW LEVEL SECURITY;

-- Policies
CREATE POLICY "Admin can view activity logs" ON public.admin_activity_log
    FOR SELECT USING (auth.jwt() ->> 'role' = 'admin' OR EXISTS (SELECT 1 FROM admin_user WHERE id = auth.uid()));

-- Seed some sample data
INSERT INTO public.admin_activity_log (title, subtitle, activity_type) VALUES
('New vendor registered: Grand Ballroom KL', 'Venues category', 'registration'),
('Payment received: RM 8,500 from Ahmad Faiz', 'Wedding booking confirmed', 'payment'),
('Dispute resolved: Refund processed', 'Catering service issue', 'dispute'),
('New customer registered: Sarah Johnson', 'Customer account created', 'registration')
ON CONFLICT DO NOTHING;
