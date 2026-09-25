-- EVENT PLANNING AND GUEST MANAGEMENT TABLES

-- 1. Event Invitations
CREATE TABLE IF NOT EXISTS event_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    guest_email TEXT NOT NULL,
    guest_name TEXT,
    guest_phone TEXT,
    status TEXT DEFAULT 'pending', -- pending / sent / viewed / accepted / declined
    invitation_code TEXT UNIQUE,
    personal_message TEXT,
    allow_plus_one BOOLEAN DEFAULT false,
    max_plus_ones INTEGER DEFAULT 0,
    sent_at TIMESTAMP WITH TIME ZONE,
    viewed_at TIMESTAMP WITH TIME ZONE,
    responded_at TIMESTAMP WITH TIME ZONE,
    rsvp_response TEXT,
    plus_one_names TEXT[], -- Array of names
    additional_data JSONB DEFAULT '{}',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Event Guests
CREATE TABLE IF NOT EXISTS event_guests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invitation_id UUID REFERENCES event_invitations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    is_attending BOOLEAN DEFAULT false,
    number_of_guests INTEGER DEFAULT 1,
    dietary_requirements TEXT,
    seating_preference TEXT,
    additional_notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Event Checklists
CREATE TABLE IF NOT EXISTS event_checklists (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    category TEXT DEFAULT 'General',
    is_done BOOLEAN DEFAULT false,
    due_date TIMESTAMP WITH TIME ZONE,
    priority TEXT DEFAULT 'medium', -- low / medium / high
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Event Timeline
CREATE TABLE IF NOT EXISTS event_timeline (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    notes TEXT,
    category TEXT DEFAULT 'General',
    date TIMESTAMP WITH TIME ZONE NOT NULL,
    duration_minutes INTEGER DEFAULT 60,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Event Photo Albums
CREATE TABLE IF NOT EXISTS event_photo_albums (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    title TEXT NOT NULL,
    description TEXT,
    is_private BOOLEAN DEFAULT false,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 6. Event Photos
CREATE TABLE IF NOT EXISTS event_photos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    album_id UUID REFERENCES event_photo_albums(id) ON DELETE CASCADE,
    url TEXT NOT NULL,
    caption TEXT,
    uploaded_by UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    is_approved BOOLEAN DEFAULT true,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 7. Event Guest Chat Messages
CREATE TABLE IF NOT EXISTS event_guest_chat_messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID REFERENCES events(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    user_name TEXT NOT NULL,
    user_image TEXT,
    message TEXT NOT NULL,
    image_url TEXT,
    timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Enable RLS for all new tables
ALTER TABLE event_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_guests ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_checklists ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_timeline ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_photo_albums ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_guest_chat_messages ENABLE ROW LEVEL SECURITY;

-- POLICIES

-- Helper function to check if user is host of the event
CREATE OR REPLACE FUNCTION is_event_host(event_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM events 
        WHERE id = event_uuid AND host_id = auth.uid()
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- event_invitations policies
DROP POLICY IF EXISTS "Hosts can manage invitations" ON event_invitations;
CREATE POLICY "Hosts can manage invitations" ON event_invitations
    FOR ALL USING (is_event_host(event_id));

DROP POLICY IF EXISTS "Public can view invitation by code" ON event_invitations;
CREATE POLICY "Public can view invitation by code" ON event_invitations
    FOR SELECT USING (true); -- Usually filtered by code in app, but for RSVP we need access

-- event_guests policies
DROP POLICY IF EXISTS "Hosts can manage guests" ON event_guests;
CREATE POLICY "Hosts can manage guests" ON event_guests
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM event_invitations i
            WHERE i.id = event_guests.invitation_id AND is_event_host(i.event_id)
        )
    );

DROP POLICY IF EXISTS "Public can insert guest from invitation" ON event_guests;
CREATE POLICY "Public can insert guest from invitation" ON event_guests
    FOR INSERT WITH CHECK (true);

-- event_checklists policies
DROP POLICY IF EXISTS "Hosts can manage checklists" ON event_checklists;
CREATE POLICY "Hosts can manage checklists" ON event_checklists
    FOR ALL USING (is_event_host(event_id));

-- event_timeline policies
DROP POLICY IF EXISTS "Hosts can manage timeline" ON event_timeline;
CREATE POLICY "Hosts can manage timeline" ON event_timeline
    FOR ALL USING (is_event_host(event_id));

DROP POLICY IF EXISTS "Guests can view timeline" ON event_timeline;
CREATE POLICY "Guests can view timeline" ON event_timeline
    FOR SELECT USING (true);

-- event_photo_albums policies
DROP POLICY IF EXISTS "Hosts can manage albums" ON event_photo_albums;
CREATE POLICY "Hosts can manage albums" ON event_photo_albums
    FOR ALL USING (is_event_host(event_id));

DROP POLICY IF EXISTS "Guests can view albums" ON event_photo_albums;
CREATE POLICY "Guests can view albums" ON event_photo_albums
    FOR SELECT USING (true);

-- event_photos policies
DROP POLICY IF EXISTS "Hosts can manage photos" ON event_photos;
CREATE POLICY "Hosts can manage photos" ON event_photos
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM event_photo_albums a
            WHERE a.id = event_photos.album_id AND is_event_host(a.event_id)
        )
    );

DROP POLICY IF EXISTS "Authenticated can upload photos" ON event_photos;
CREATE POLICY "Authenticated can upload photos" ON event_photos
    FOR INSERT WITH CHECK (auth.role() = 'authenticated');

-- event_guest_chat_messages policies
DROP POLICY IF EXISTS "Authenticated can chat" ON event_guest_chat_messages;
CREATE POLICY "Authenticated can chat" ON event_guest_chat_messages
    FOR ALL USING (auth.role() = 'authenticated');

DROP POLICY IF EXISTS "Public can view chat" ON event_guest_chat_messages;
CREATE POLICY "Public can view chat" ON event_guest_chat_messages
    FOR SELECT USING (true);

-- Also fix gift_registries policies which were missing in original migration
DO $$ 
BEGIN
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'gift_registries') THEN
        DROP POLICY IF EXISTS "Hosts can manage registries" ON gift_registries;
        CREATE POLICY "Hosts can manage registries" ON gift_registries FOR ALL USING (is_event_host(event_id));
        
        DROP POLICY IF EXISTS "Anyone can view registries" ON gift_registries;
        CREATE POLICY "Anyone can view registries" ON gift_registries FOR SELECT USING (true);
    END IF;
    
    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'gift_registry_items') THEN
        DROP POLICY IF EXISTS "Hosts can manage registry items" ON gift_registry_items;
        CREATE POLICY "Hosts can manage registry items" ON gift_registry_items FOR ALL USING (
            EXISTS (SELECT 1 FROM gift_registries r WHERE r.id = gift_registry_items.registry_id AND is_event_host(r.event_id))
        );
        
        DROP POLICY IF EXISTS "Anyone can view registry items" ON gift_registry_items;
        CREATE POLICY "Anyone can view registry items" ON gift_registry_items FOR SELECT USING (true);
        
        DROP POLICY IF EXISTS "Anyone can update registry items" ON gift_registry_items;
        CREATE POLICY "Anyone can update registry items" ON gift_registry_items FOR UPDATE USING (true);
    END IF;

    IF EXISTS (SELECT FROM pg_tables WHERE tablename = 'event_wishes') THEN
        DROP POLICY IF EXISTS "Anyone can add wishes" ON event_wishes;
        CREATE POLICY "Anyone can add wishes" ON event_wishes FOR INSERT WITH CHECK (true);
        
        DROP POLICY IF EXISTS "Anyone can view wishes" ON event_wishes;
        CREATE POLICY "Anyone can view wishes" ON event_wishes FOR SELECT USING (true);
    END IF;
END $$;
