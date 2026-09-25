-- =====================================================
-- FIX GUEST ROW LEVEL SECURITY (RLS) POLICIES
-- Allows guests to view events, invitations, RSVP, 
-- use registries, upload photos, and chat.
-- =====================================================

-- 1. EVENTS Table Policies
-- Allow anyone to view events that have at least one invitation
-- (or simply allow SELECT using true since guests fetch by direct UUID)
DO $$ 
BEGIN 
    DROP POLICY IF EXISTS "Public/Guests can view events with invitations" ON events;
    DROP POLICY IF EXISTS "Guests can view events they are invited to" ON events;
END $$;

CREATE POLICY "Guests can view events they are invited to" ON events
    FOR SELECT USING (
        is_public = true OR
        auth.uid()::text = host_id OR
        EXISTS (
            SELECT 1 FROM event_invitations 
            WHERE event_invitations.event_id = id
        )
    );


-- 2. EVENT INVITATIONS Table Policies
-- Guests must be able to read and update their invitation (e.g. to RSVP)
DO $$ 
BEGIN 
    DROP POLICY IF EXISTS "Public can read invitation by code" ON event_invitations;
    DROP POLICY IF EXISTS "Public can read and update invitations" ON event_invitations;
    DROP POLICY IF EXISTS "Public can update invitations" ON event_invitations;
END $$;

CREATE POLICY "Public can read invitations" ON event_invitations
    FOR SELECT USING (true);

CREATE POLICY "Public can update invitations" ON event_invitations
    FOR UPDATE USING (true);

CREATE POLICY "Public can insert invitations" ON event_invitations
    FOR INSERT WITH CHECK (true);


-- 3. EVENT GUESTS Table Policies
-- Guests must be able to manage their own attendance records
DO $$ 
BEGIN 
    DROP POLICY IF EXISTS "Guests can manage their own guest info" ON event_guests;
END $$;

CREATE POLICY "Guests can manage their own guest info" ON event_guests
    FOR ALL USING (true);


-- 4. GIFT REGISTRIES Table Policies
-- Guests must be able to view gift registries for events they are invited to
DO $$ 
BEGIN 
    DROP POLICY IF EXISTS "Guests can view registries" ON event_gift_registries;
END $$;

CREATE POLICY "Guests can view registries" ON event_gift_registries
    FOR SELECT USING (true);


-- 5. GIFT REGISTRY ITEMS Table Policies
-- Guests must be able to view and update items (e.g. to mark as purchased)
DO $$ 
BEGIN 
    DROP POLICY IF EXISTS "Guests can view registry items" ON event_gift_registry_items;
    DROP POLICY IF EXISTS "Guests can update registry items" ON event_gift_registry_items;
END $$;

CREATE POLICY "Guests can view registry items" ON event_gift_registry_items
    FOR SELECT USING (true);

CREATE POLICY "Guests can update registry items" ON event_gift_registry_items
    FOR UPDATE USING (true);


-- 6. PHOTO ALBUMS Table Policies
-- Guests must be able to view photo albums
DO $$ 
BEGIN 
    DROP POLICY IF EXISTS "Guests can view photo albums" ON event_photo_albums;
END $$;

CREATE POLICY "Guests can view photo albums" ON event_photo_albums
    FOR SELECT USING (true);


-- 7. EVENT PHOTOS Table Policies
-- Guests must be able to view photos and upload new photos
DO $$ 
BEGIN 
    DROP POLICY IF EXISTS "Guests can view photos" ON event_photos;
    DROP POLICY IF EXISTS "Guests can upload photos" ON event_photos;
END $$;

CREATE POLICY "Guests can view photos" ON event_photos
    FOR SELECT USING (true);

CREATE POLICY "Guests can upload photos" ON event_photos
    FOR INSERT WITH CHECK (true);


-- 8. GUEST CHAT MESSAGES Table Policies
-- Guests must be able to view and send chat messages
DO $$ 
BEGIN 
    DROP POLICY IF EXISTS "Guests can view chat messages" ON event_guest_chat_messages;
    DROP POLICY IF EXISTS "Guests can send chat messages" ON event_guest_chat_messages;
END $$;

CREATE POLICY "Guests can view chat messages" ON event_guest_chat_messages
    FOR SELECT USING (true);

CREATE POLICY "Guests can send chat messages" ON event_guest_chat_messages
    FOR INSERT WITH CHECK (true);
