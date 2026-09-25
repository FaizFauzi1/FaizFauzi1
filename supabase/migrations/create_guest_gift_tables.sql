-- Create Gift Registries table
CREATE TABLE IF NOT EXISTS gift_registries (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create Gift Registry Items table
CREATE TABLE IF NOT EXISTS gift_registry_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    registry_id UUID REFERENCES gift_registries(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10, 2) DEFAULT 0.00,
    image_url TEXT,
    category TEXT,
    quantity INTEGER DEFAULT 1,
    remaining_quantity INTEGER DEFAULT 1,
    is_purchased BOOLEAN DEFAULT false,
    purchased_by TEXT,
    purchased_at TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create Event Wishes table
CREATE TABLE IF NOT EXISTS event_wishes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    guest_id TEXT,
    guest_name TEXT NOT NULL,
    message TEXT NOT NULL,
    is_public BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS
ALTER TABLE gift_registries ENABLE ROW LEVEL SECURITY;
ALTER TABLE gift_registry_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_wishes ENABLE ROW LEVEL SECURITY;

-- Basic Policies (Adjust based on your auth structure)
-- For now, allowing authenticated users to read and only owners/hosts to manage.
-- Note: guest-facing logic might need specific policies if they aren't fully authenticated.
