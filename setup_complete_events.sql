-- ===========================================
-- 1. Create Tables (IF NOT EXISTS)
-- ===========================================

-- Events table
CREATE TABLE IF NOT EXISTS events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    title TEXT NOT NULL,
    description TEXT,
    type TEXT NOT NULL,
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE,
    venue_id UUID,
    venue_data JSONB,
    host_id TEXT NOT NULL, -- KEEPING AS TEXT because existing table likely has it as TEXT
    host_name TEXT NOT NULL,
    host_email TEXT,
    host_phone TEXT,
    host_profile_image TEXT,
    status TEXT DEFAULT 'draft',
    theme TEXT,
    dress_code TEXT,
    max_guests INTEGER DEFAULT 100,
    is_public BOOLEAN DEFAULT false,
    invitation_message TEXT,
    cover_image TEXT,
    tags TEXT[],
    additional_info JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Event Invitations
CREATE TABLE IF NOT EXISTS event_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    guest_email TEXT NOT NULL,
    guest_name TEXT,
    guest_phone TEXT,
    status TEXT DEFAULT 'sent',
    invitation_code TEXT NOT NULL,
    personal_message TEXT,
    allow_plus_one BOOLEAN DEFAULT false,
    max_plus_ones INTEGER DEFAULT 0,
    sent_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    viewed_at TIMESTAMP WITH TIME ZONE,
    responded_at TIMESTAMP WITH TIME ZONE,
    rsvp_response TEXT,
    plus_one_names TEXT[],
    additional_data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Event Guests
CREATE TABLE IF NOT EXISTS event_guests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invitation_id UUID NOT NULL REFERENCES event_invitations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    is_attending BOOLEAN DEFAULT false,
    number_of_guests INTEGER DEFAULT 0,
    dietary_preferences TEXT,
    seating_preference TEXT,
    meal_choice TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Gift Registries
CREATE TABLE IF NOT EXISTS event_gift_registries (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    is_active BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Gift Registry Items
CREATE TABLE IF NOT EXISTS event_gift_registry_items (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    registry_id UUID NOT NULL REFERENCES event_gift_registries(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    image_url TEXT,
    category TEXT,
    is_purchased BOOLEAN DEFAULT false,
    purchased_by TEXT,
    purchased_at TIMESTAMP WITH TIME ZONE,
    quantity INTEGER DEFAULT 1,
    remaining_quantity INTEGER DEFAULT 1
);

-- Photo Albums
CREATE TABLE IF NOT EXISTS event_photo_albums (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    allow_guest_uploads BOOLEAN DEFAULT true,
    require_approval BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Event Photos
CREATE TABLE IF NOT EXISTS event_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    album_id UUID NOT NULL REFERENCES event_photo_albums(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    thumbnail_url TEXT,
    caption TEXT,
    uploaded_by TEXT NOT NULL,
    uploaded_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    tags TEXT[],
    is_approved BOOLEAN DEFAULT true
);

-- Guest Chat Messages
CREATE TABLE IF NOT EXISTS event_guest_chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    sender_id TEXT NOT NULL,
    sender_name TEXT NOT NULL,
    sender_avatar TEXT,
    content TEXT,
    type TEXT DEFAULT 'text',
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    is_read BOOLEAN DEFAULT false,
    read_by TEXT[],
    reply_to_message_id UUID,
    metadata JSONB DEFAULT '{}'
);

-- ===========================================
-- 2. Enable Row Level Security (RLS)
-- ===========================================

ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_guests ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_gift_registries ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_gift_registry_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_photo_albums ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_guest_chat_messages ENABLE ROW LEVEL SECURITY;

-- ===========================================
-- 3. Define Policies (WITH TYPE CASTING FIXES)
-- ===========================================

-- EVENTS Policies
DO $$ 
BEGIN 
    DROP POLICY IF EXISTS "Hosts can view their own events" ON events;
    DROP POLICY IF EXISTS "Hosts can create events" ON events;
    DROP POLICY IF EXISTS "Hosts can update their own events" ON events;
    DROP POLICY IF EXISTS "Hosts can delete their own events" ON events;
    DROP POLICY IF EXISTS "Public events are viewable by everyone" ON events;
END $$;

-- Fix: Cast auth.uid() to text to compare with text host_id
CREATE POLICY "Hosts can view their own events" ON events
    FOR SELECT USING (auth.uid()::text = host_id);

CREATE POLICY "Hosts can create events" ON events
    FOR INSERT WITH CHECK (auth.uid()::text = host_id);

CREATE POLICY "Hosts can update their own events" ON events
    FOR UPDATE USING (auth.uid()::text = host_id);

CREATE POLICY "Hosts can delete their own events" ON events
    FOR DELETE USING (auth.uid()::text = host_id);

CREATE POLICY "Public events are viewable by everyone" ON events
    FOR SELECT USING (is_public = true);


-- EVENT INVITATIONS Policies
DO $$ BEGIN DROP POLICY IF EXISTS "Hosts can view invitations" ON event_invitations; END $$;
CREATE POLICY "Hosts can view invitations" ON event_invitations
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM events WHERE id = event_invitations.event_id AND host_id = auth.uid()::text)
    );

DO $$ BEGIN DROP POLICY IF EXISTS "Hosts can create invitations" ON event_invitations; END $$;
CREATE POLICY "Hosts can create invitations" ON event_invitations
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM events WHERE id = event_invitations.event_id AND host_id = auth.uid()::text)
    );

-- EVENT GUESTS Policies
DO $$ BEGIN DROP POLICY IF EXISTS "Hosts can view guests" ON event_guests; END $$;
CREATE POLICY "Hosts can view guests" ON event_guests
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM event_invitations 
            JOIN events ON events.id = event_invitations.event_id
            WHERE event_invitations.id = event_guests.invitation_id AND events.host_id = auth.uid()::text
        )
    );

DO $$ BEGIN DROP POLICY IF EXISTS "Hosts can manage guests" ON event_guests; END $$;
CREATE POLICY "Hosts can manage guests" ON event_guests
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM event_invitations 
            JOIN events ON events.id = event_invitations.event_id
            WHERE event_invitations.id = event_guests.invitation_id AND events.host_id = auth.uid()::text
        )
    );

-- GIFT REGISTRY & ITEMS Policies
DO $$ BEGIN DROP POLICY IF EXISTS "Hosts can manage registries" ON event_gift_registries; END $$;
CREATE POLICY "Hosts can manage registries" ON event_gift_registries
    FOR ALL USING (
        EXISTS (SELECT 1 FROM events WHERE id = event_gift_registries.event_id AND host_id = auth.uid()::text)
    );

DO $$ BEGIN DROP POLICY IF EXISTS "Hosts can manage registry items" ON event_gift_registry_items; END $$;
CREATE POLICY "Hosts can manage registry items" ON event_gift_registry_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM event_gift_registries 
            JOIN events ON events.id = event_gift_registries.event_id 
            WHERE event_gift_registries.id = event_gift_registry_items.registry_id AND events.host_id = auth.uid()::text
        )
    );

-- PHOTO ALBUMS & PHOTOS Policies
DO $$ BEGIN DROP POLICY IF EXISTS "Hosts can manage albums" ON event_photo_albums; END $$;
CREATE POLICY "Hosts can manage albums" ON event_photo_albums
    FOR ALL USING (
         EXISTS (SELECT 1 FROM events WHERE id = event_photo_albums.event_id AND host_id = auth.uid()::text)
    );

DO $$ BEGIN DROP POLICY IF EXISTS "Hosts can manage photos" ON event_photos; END $$;
CREATE POLICY "Hosts can manage photos" ON event_photos
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM event_photo_albums
            JOIN events ON events.id = event_photo_albums.event_id
            WHERE event_photo_albums.id = event_photos.album_id AND events.host_id = auth.uid()::text
        )
    );

-- CHAT MESSAGES Policies
DO $$ BEGIN DROP POLICY IF EXISTS "Hosts can manage chat" ON event_guest_chat_messages; END $$;
CREATE POLICY "Hosts can manage chat" ON event_guest_chat_messages
    FOR ALL USING (
         EXISTS (SELECT 1 FROM events WHERE id = event_guest_chat_messages.event_id AND host_id = auth.uid()::text)
    );
