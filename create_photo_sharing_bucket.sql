-- ==========================================
-- CREATE PHOTO SHARING BUCKET AND POLICIES
-- ==========================================

-- 1. Create the 'event-photos' bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('event-photos', 'event-photos', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Enable RLS on objects (Usually already enabled, commenting out to avoid permission errors)
-- ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Cleanup existing policies for this bucket
DROP POLICY IF EXISTS "Public Read Event Photos" ON storage.objects;
DROP POLICY IF EXISTS "Guests Can Upload Event Photos" ON storage.objects;
DROP POLICY IF EXISTS "Hosts Can Manage Event Photos" ON storage.objects;
DROP POLICY IF EXISTS "Users Can Delete Own Event Photos" ON storage.objects;

-- 4. Policy: Allow anyone to view event photos (public read)
CREATE POLICY "Public Read Event Photos"
ON storage.objects FOR SELECT
USING (bucket_id = 'event-photos');

-- 5. Policy: Allow authenticated users to upload photos
CREATE POLICY "Guests Can Upload Event Photos"
ON storage.objects FOR INSERT
WITH CHECK (bucket_id = 'event-photos' AND auth.role() = 'authenticated');

-- 6. Policy: Allow users to delete their own uploaded photos
CREATE POLICY "Users Can Delete Own Event Photos"
ON storage.objects FOR DELETE
USING (bucket_id = 'event-photos' AND auth.uid() = owner);

-- 7. Ensure event_photos table has correct policies
-- Already handled in fix_guest_rls_policies.sql, but let's double check/ensure

DROP POLICY IF EXISTS "Guests can view photos" ON event_photos;
CREATE POLICY "Guests can view photos" ON event_photos
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Guests can upload photos" ON event_photos;
CREATE POLICY "Guests can upload photos" ON event_photos
    FOR INSERT WITH CHECK (true);

DROP POLICY IF EXISTS "Hosts can manage photos" ON event_photos;
CREATE POLICY "Hosts can manage photos" ON event_photos
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM event_photo_albums a
            JOIN events e ON e.id = a.event_id
            WHERE a.id = event_photos.album_id AND e.host_id = auth.uid()::text
        )
    );

-- 8. Update event_photo_albums table schema
ALTER TABLE event_photo_albums ADD COLUMN IF NOT EXISTS max_photos_per_guest INTEGER DEFAULT 50;

-- 9. Ensure event_photo_albums table has correct policies
DROP POLICY IF EXISTS "Guests can view photo albums" ON event_photo_albums;
CREATE POLICY "Guests can view photo albums" ON event_photo_albums
    FOR SELECT USING (true);

DROP POLICY IF EXISTS "Guests can create photo albums" ON event_photo_albums;
CREATE POLICY "Guests can create photo albums" ON event_photo_albums
    FOR INSERT WITH CHECK (true);
