-- ==========================================
-- FIX VENDOR ASSETS BUCKET POLICIES
-- ==========================================

-- 1. Create the 'vendor_assets' bucket if it doesn't exist
INSERT INTO storage.buckets (id, name, public)
VALUES ('vendor_assets', 'vendor_assets', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 2. Enable RLS on objects (Usually already enabled, commenting out to avoid permission errors)
-- ALTER TABLE storage.objects ENABLE ROW LEVEL SECURITY;

-- 3. Cleanup existing policies for this bucket to avoid conflicts
DROP POLICY IF EXISTS "Public Read Vendor Assets" ON storage.objects;
DROP POLICY IF EXISTS "Vendors Can Upload Assets" ON storage.objects;
DROP POLICY IF EXISTS "Vendors Can Update Assets" ON storage.objects;
DROP POLICY IF EXISTS "Vendors Can Delete Assets" ON storage.objects;

-- 4. Policy: Allow anyone to view assets (public read)
CREATE POLICY "Public Read Vendor Assets"
ON storage.objects FOR SELECT
USING (bucket_id = 'vendor_assets');

-- 5. Policy: Allow authenticated vendors to upload to their own folder
-- Path format: vendor_id/portfolio_images/filename.jpg
-- matches: (storage.foldername(name))[1] should be the user's ID
CREATE POLICY "Vendors Can Upload Assets"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'vendor_assets' AND 
    (storage.foldername(name))[1] = auth.uid()::text
);

-- 6. Policy: Allow vendors to update their own assets
CREATE POLICY "Vendors Can Update Assets"
ON storage.objects FOR UPDATE
TO authenticated
USING (
    bucket_id = 'vendor_assets' AND 
    (storage.foldername(name))[1] = auth.uid()::text
)
WITH CHECK (
    bucket_id = 'vendor_assets' AND 
    (storage.foldername(name))[1] = auth.uid()::text
);

-- 7. Policy: Allow vendors to delete their own assets
CREATE POLICY "Vendors Can Delete Assets"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'vendor_assets' AND 
    (storage.foldername(name))[1] = auth.uid()::text
);
