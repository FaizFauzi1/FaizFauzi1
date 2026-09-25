
-- ==========================================
-- CREATE DEDICATED SERVICE IMAGES BUCKET
-- ==========================================

-- 1. Create the 'service-images' bucket
INSERT INTO storage.buckets (id, name, public)
VALUES ('service-images', 'service-images', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Enable RLS
ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Cleanup existing policies for this bucket
DROP POLICY IF EXISTS "Public Read Service Images" ON storage.objects;
DROP POLICY IF EXISTS "Vendors Can Upload Service Images" ON storage.objects;
DROP POLICY IF EXISTS "Vendors Can Delete Service Images" ON storage.objects;

-- 4. Policy: Allow anyone to view service images (since public = true)
CREATE POLICY "Public Read Service Images"
ON storage.objects FOR SELECT
USING (bucket_id = 'service-images');

-- 5. Policy: Allow logged-in vendors to upload to their own folder
-- Path format: vendor_id/filename.jpg
CREATE POLICY "Vendors Can Upload Service Images"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'service-images' AND 
    (storage.foldername(name))[1] = auth.uid()::text
);

-- 6. Policy: Allow vendors to delete their own images
CREATE POLICY "Vendors Can Delete Service Images"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'service-images' AND 
    (storage.foldername(name))[1] = auth.uid()::text
);
