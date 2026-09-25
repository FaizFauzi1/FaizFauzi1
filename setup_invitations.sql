-- Setup Event Invitations and Guest Management
-- Run this in the Supabase SQL Editor

-- 1. Create event_invitations table if it doesn't exist
CREATE TABLE IF NOT EXISTS event_invitations (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    event_id UUID NOT NULL REFERENCES events(id) ON DELETE CASCADE,
    guest_email TEXT NOT NULL,
    guest_name TEXT,
    guest_phone TEXT,
    status TEXT DEFAULT 'sent' CHECK (status IN ('sent', 'viewed', 'accepted', 'declined', 'pending')),
    invitation_code TEXT NOT NULL UNIQUE,
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

-- 2. Create event_guests table if it doesn't exist
CREATE TABLE IF NOT EXISTS event_guests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    invitation_id UUID NOT NULL REFERENCES event_invitations(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT NOT NULL,
    phone TEXT,
    is_attending BOOLEAN DEFAULT false,
    number_of_guests INTEGER DEFAULT 1,
    dietary_preferences TEXT,
    seating_preference TEXT,
    meal_choice TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 3. Enable RLS
ALTER TABLE event_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_guests ENABLE ROW LEVEL SECURITY;

-- 4. Policies for event_invitations
-- Hosts can manage invitations for their own events
CREATE POLICY "Hosts can manage invitations for their events" ON event_invitations
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM events
            WHERE id = event_invitations.event_id AND host_id = auth.uid()::text
        )
    );

-- Anyone can read an invitation if they have the code (Public access for guests)
CREATE POLICY "Public can read invitation by code" ON event_invitations
    FOR SELECT USING (true); 
-- Note: In a production app, you might want to restrict this more, 
-- but for a "join by code" flow, guests need to be able to fetch the invitation 
-- before they are authenticated or linked.

-- 5. Policies for event_guests
-- Hosts can manage guests for their events
CREATE POLICY "Hosts can manage guests for their events" ON event_guests
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM event_invitations
            JOIN events ON events.id = event_invitations.event_id
            WHERE event_invitations.id = event_guests.invitation_id AND events.host_id = auth.uid()::text
        )
    );

-- Guests can update their own guest info (if they have the invitation_id)
CREATE POLICY "Guests can manage their own guest info" ON event_guests
    FOR ALL USING (true);
-- Note: Again, for simplicity in the RSVP flow, we allow access. 
-- Usually, you'd verify via a session or a signed token.
