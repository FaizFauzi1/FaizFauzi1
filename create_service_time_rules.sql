-- ===========================================
-- SERVICE TIME RULES SCHEMA
-- ===========================================

-- 1. Create enum for time types
DO $$ BEGIN
    CREATE TYPE service_time_type AS ENUM (
        'fixed_slot',
        'flexible_hour',
        'session',
        'full_day',
        'date_range'
    );
EXCEPTION
    WHEN duplicate_object THEN null;
END $$;

-- 2. Create service_time_rules table
CREATE TABLE IF NOT EXISTS service_time_rules (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    service_id UUID NOT NULL REFERENCES vendor_services(id) ON DELETE CASCADE,
    time_type service_time_type NOT NULL DEFAULT 'flexible_hour',
    
    -- Slot Configuration (for fixed_slot)
    slot_duration_minutes INTEGER,
    
    -- Duration Configuration (for flexible_hour)
    min_duration_minutes INTEGER,
    max_duration_minutes INTEGER,
    duration_step_minutes INTEGER DEFAULT 60,
    
    -- Buffer Configuration
    buffer_before_minutes INTEGER DEFAULT 0,
    buffer_after_minutes INTEGER DEFAULT 0,
    
    -- Session Configuration (for session - stored as JSONB for flexibility)
    -- Format: [{"name": "Morning", "start": "08:00", "end": "12:00", "price_multiplier": 1.0}]
    sessions JSONB DEFAULT '[]',
    
    -- General Rules
    allow_multi_day BOOLEAN DEFAULT false,
    max_days INTEGER,
    
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    
    UNIQUE(service_id)
);

-- 3. Add RLS Policies
ALTER TABLE service_time_rules ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Anyone can view service time rules" ON service_time_rules;
CREATE POLICY "Anyone can view service time rules" ON service_time_rules
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Vendors can manage their own service time rules" ON service_time_rules;
CREATE POLICY "Vendors can manage their own service time rules" ON service_time_rules
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM vendor_services
            WHERE id = service_time_rules.service_id
            AND vendor_id = auth.uid()
        )
    );

-- 4. Trigger to update updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

DROP TRIGGER IF EXISTS tr_service_time_rules_updated_at ON service_time_rules;
CREATE TRIGGER tr_service_time_rules_updated_at
    BEFORE UPDATE ON service_time_rules
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
