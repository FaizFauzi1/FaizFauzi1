-- Enable RLS on Event Management Tables
ALTER TABLE events ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_invitations ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_guests ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_gift_registries ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_gift_registry_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_photo_albums ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_photos ENABLE ROW LEVEL SECURITY;
ALTER TABLE event_guest_chat_messages ENABLE ROW LEVEL SECURITY;

-- EVENTS Policies
-- Host can view their own events
CREATE POLICY "Hosts can view their own events" ON events
    FOR SELECT USING (auth.uid() = host_id);

-- Host can insert their own events
CREATE POLICY "Hosts can create events" ON events
    FOR INSERT WITH CHECK (auth.uid() = host_id);

-- Host can update their own events
CREATE POLICY "Hosts can update their own events" ON events
    FOR UPDATE USING (auth.uid() = host_id);

-- Host can delete their own events
CREATE POLICY "Hosts can delete their own events" ON events
    FOR DELETE USING (auth.uid() = host_id);

-- Public events (optional, if IS_PUBLIC is true)
CREATE POLICY "Public events are viewable by everyone" ON events
    FOR SELECT USING (is_public = true);


-- EVENT INVITATIONS Policies
-- Host can view invitations for their events
CREATE POLICY "Hosts can view invitations" ON event_invitations
    FOR SELECT USING (
        EXISTS (SELECT 1 FROM events WHERE id = event_invitations.event_id AND host_id = auth.uid())
    );

-- Host can create invitations
CREATE POLICY "Hosts can create invitations" ON event_invitations
    FOR INSERT WITH CHECK (
        EXISTS (SELECT 1 FROM events WHERE id = event_invitations.event_id AND host_id = auth.uid())
    );

-- EVENT GUESTS Policies
-- Host can view guests
CREATE POLICY "Hosts can view guests" ON event_guests
    FOR SELECT USING (
        EXISTS (
            SELECT 1 FROM event_invitations 
            JOIN events ON events.id = event_invitations.event_id
            WHERE event_invitations.id = event_guests.invitation_id AND events.host_id = auth.uid()
        )
    );

-- Host can manage guests
CREATE POLICY "Hosts can manage guests" ON event_guests
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM event_invitations 
            JOIN events ON events.id = event_invitations.event_id
            WHERE event_invitations.id = event_guests.invitation_id AND events.host_id = auth.uid()
        )
    );

-- GIFT REGISTRY & ITEMS Policies
CREATE POLICY "Hosts can manage registries" ON event_gift_registries
    FOR ALL USING (
        EXISTS (SELECT 1 FROM events WHERE id = event_gift_registries.event_id AND host_id = auth.uid())
    );

CREATE POLICY "Hosts can manage registry items" ON event_gift_registry_items
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM event_gift_registries 
            JOIN events ON events.id = event_gift_registries.event_id 
            WHERE event_gift_registries.id = event_gift_registry_items.registry_id AND events.host_id = auth.uid()
        )
    );

-- PHOTO ALBUMS & PHOTOS Policies
CREATE POLICY "Hosts can manage albums" ON event_photo_albums
    FOR ALL USING (
         EXISTS (SELECT 1 FROM events WHERE id = event_photo_albums.event_id AND host_id = auth.uid())
    );

CREATE POLICY "Hosts can manage photos" ON event_photos
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM event_photo_albums
            JOIN events ON events.id = event_photo_albums.event_id
            WHERE event_photo_albums.id = event_photos.album_id AND events.host_id = auth.uid()
        )
    );

-- CHAT MESSAGES Policies
CREATE POLICY "Hosts can manage chat" ON event_guest_chat_messages
    FOR ALL USING (
         EXISTS (SELECT 1 FROM events WHERE id = event_guest_chat_messages.event_id AND host_id = auth.uid())
    );
