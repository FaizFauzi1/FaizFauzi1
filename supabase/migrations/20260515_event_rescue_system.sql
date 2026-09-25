-- ==============================================================================
-- PHASE 1: EVENTEASE RESCUE SYSTEM (INCIDENTS, CHECK-INS, EMERGENCY VENDORS)
-- ==============================================================================

-- 1. Modify vendor_profiles to support emergency capabilities
ALTER TABLE public.vendor_profiles 
ADD COLUMN IF NOT EXISTS reliability_score INTEGER DEFAULT 100 CHECK (reliability_score >= 0 AND reliability_score <= 100),
ADD COLUMN IF NOT EXISTS is_emergency_partner BOOLEAN DEFAULT false;

-- 2. Create vendor_checkins table for tracking arrival and status
CREATE TABLE IF NOT EXISTS public.vendor_checkins (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    vendor_id UUID NOT NULL REFERENCES public.vendor_profiles(id) ON DELETE CASCADE,
    status TEXT NOT NULL CHECK (status IN ('on_the_way', 'arrived', 'started', 'completed')),
    location_lat DOUBLE PRECISION,
    location_lng DOUBLE PRECISION,
    proof_image_url TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_vendor_checkins_booking ON public.vendor_checkins(booking_id);
CREATE INDEX IF NOT EXISTS idx_vendor_checkins_vendor ON public.vendor_checkins(vendor_id);

-- Enable RLS for check-ins
ALTER TABLE public.vendor_checkins ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Vendors can view and create their own check-ins" 
ON public.vendor_checkins FOR ALL TO authenticated 
USING (vendor_id IN (SELECT id FROM public.vendor_profiles WHERE user_id = auth.uid()))
WITH CHECK (vendor_id IN (SELECT id FROM public.vendor_profiles WHERE user_id = auth.uid()));

CREATE POLICY "Customers can view check-ins for their bookings" 
ON public.vendor_checkins FOR SELECT TO authenticated 
USING (
    booking_id IN (SELECT id FROM public.bookings WHERE customer_id = auth.uid())
);

CREATE POLICY "Admins can view all check-ins" 
ON public.vendor_checkins FOR ALL TO authenticated 
USING (
    EXISTS (SELECT 1 FROM public.admin_user WHERE id = auth.uid()) OR
    (SELECT role FROM public.users WHERE id = auth.uid()) IN ('admin', 'super_admin')
);

-- 3. Create event_incidents table for the Rescue Room
CREATE TABLE IF NOT EXISTS public.event_incidents (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    booking_id UUID NOT NULL REFERENCES public.bookings(id) ON DELETE CASCADE,
    customer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    vendor_id UUID NOT NULL REFERENCES public.vendor_profiles(id) ON DELETE CASCADE,
    incident_type TEXT NOT NULL CHECK (incident_type IN ('vendor_no_show', 'vendor_late', 'equipment_failure', 'wrong_service', 'emergency', 'other')),
    priority TEXT NOT NULL CHECK (priority IN ('critical', 'high', 'medium', 'low')),
    status TEXT NOT NULL DEFAULT 'open' CHECK (status IN ('open', 'investigating', 'searching_backup', 'backup_found', 'resolved', 'closed')),
    description TEXT,
    evidence_urls TEXT[],
    resolution_notes TEXT,
    backup_vendor_id UUID REFERENCES public.vendor_profiles(id) ON DELETE SET NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_event_incidents_booking ON public.event_incidents(booking_id);
CREATE INDEX IF NOT EXISTS idx_event_incidents_customer ON public.event_incidents(customer_id);
CREATE INDEX IF NOT EXISTS idx_event_incidents_vendor ON public.event_incidents(vendor_id);
CREATE INDEX IF NOT EXISTS idx_event_incidents_status ON public.event_incidents(status);

-- Enable RLS for incidents
ALTER TABLE public.event_incidents ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Customers can view and create their own incidents" 
ON public.event_incidents FOR ALL TO authenticated 
USING (customer_id = auth.uid())
WITH CHECK (customer_id = auth.uid());

CREATE POLICY "Vendors can view incidents related to them" 
ON public.event_incidents FOR SELECT TO authenticated 
USING (
    vendor_id IN (SELECT id FROM public.vendor_profiles WHERE user_id = auth.uid()) OR
    backup_vendor_id IN (SELECT id FROM public.vendor_profiles WHERE user_id = auth.uid())
);

CREATE POLICY "Admins can manage all incidents" 
ON public.event_incidents FOR ALL TO authenticated 
USING (
    EXISTS (SELECT 1 FROM public.admin_user WHERE id = auth.uid()) OR
    (SELECT role FROM public.users WHERE id = auth.uid()) IN ('admin', 'super_admin')
);

-- Trigger for incident updated_at
CREATE OR REPLACE FUNCTION update_incident_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER update_event_incidents_updated_at
    BEFORE UPDATE ON public.event_incidents
    FOR EACH ROW
    EXECUTE FUNCTION update_incident_updated_at_column();

-- Grant permissions
GRANT ALL ON public.vendor_checkins TO authenticated;
GRANT ALL ON public.vendor_checkins TO service_role;
GRANT ALL ON public.event_incidents TO authenticated;
GRANT ALL ON public.event_incidents TO service_role;
