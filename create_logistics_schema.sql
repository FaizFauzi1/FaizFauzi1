-- ===========================================
-- LOGISTICS MODULE SCHEMA
-- ===========================================

-- 1. Create table for Service Logistics (Vendor Config)
CREATE TABLE IF NOT EXISTS service_logistics (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id UUID NOT NULL REFERENCES vendor_services(id) ON DELETE CASCADE,
    
    -- Requirements
    requires_vehicle BOOLEAN DEFAULT false,
    vehicle_type TEXT, -- van, lorry, truck, trailer, car, bike
    crew_count INTEGER DEFAULT 1,
    
    -- Timeline
    setup_time_hours DECIMAL DEFAULT 1.0,
    teardown_time_hours DECIMAL DEFAULT 1.0,
    
    -- Coverage
    free_radius_km DECIMAL DEFAULT 20.0,
    per_km_rate DECIMAL DEFAULT 0.0,
    primary_state TEXT,
    
    -- Policies
    parking_required BOOLEAN DEFAULT false,
    power_required BOOLEAN DEFAULT false,
    overnight_required BOOLEAN DEFAULT false,
    night_surcharge DECIMAL DEFAULT 0.0,
    toll_parking_policy TEXT,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(service_id)
);

-- 2. Add logistics field to bookings table
-- We use JSONB to store the BookingLogistics snapshot
ALTER TABLE bookings 
ADD COLUMN IF NOT EXISTS logistics_data JSONB DEFAULT '{}';

-- 3. Add RLS Policies for service_logistics
ALTER TABLE service_logistics ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view service logistics" ON service_logistics;
CREATE POLICY "Anyone can view service logistics" ON service_logistics
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Vendors can manage their own service logistics" ON service_logistics;
CREATE POLICY "Vendors can manage their own service logistics" ON service_logistics
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM vendor_services
            WHERE id = service_logistics.service_id
            AND vendor_id = auth.uid()
        )
    );

-- 4. Trigger for update_at
DROP TRIGGER IF EXISTS tr_service_logistics_updated_at ON service_logistics;
CREATE TRIGGER tr_service_logistics_updated_at
    BEFORE UPDATE ON service_logistics
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
