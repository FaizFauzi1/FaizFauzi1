-- Add missing social media links to vendor_profiles
ALTER TABLE vendor_profiles 
ADD COLUMN IF NOT EXISTS social_facebook TEXT,
ADD COLUMN IF NOT EXISTS social_twitter TEXT,
ADD COLUMN IF NOT EXISTS social_linkedin TEXT;

-- Create vendor_featured_posts table
CREATE TABLE IF NOT EXISTS vendor_featured_posts (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  vendor_id UUID NOT NULL REFERENCES vendor_profiles(id) ON DELETE CASCADE,
  platform TEXT NOT NULL,
  post_url TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add indexes
CREATE INDEX IF NOT EXISTS idx_vendor_featured_posts_vendor_id ON vendor_featured_posts(vendor_id);

-- Add RLS Policies
ALTER TABLE vendor_featured_posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Featured posts are viewable by everyone" ON vendor_featured_posts
  FOR SELECT USING (true);

CREATE POLICY "Vendors can insert their own featured posts" ON vendor_featured_posts
  FOR INSERT WITH CHECK (
    EXISTS (
      SELECT 1 FROM vendor_profiles 
      WHERE id = vendor_featured_posts.vendor_id 
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Vendors can update their own featured posts" ON vendor_featured_posts
  FOR UPDATE USING (
    EXISTS (
      SELECT 1 FROM vendor_profiles 
      WHERE id = vendor_featured_posts.vendor_id 
      AND user_id = auth.uid()
    )
  );

CREATE POLICY "Vendors can delete their own featured posts" ON vendor_featured_posts
  FOR DELETE USING (
    EXISTS (
      SELECT 1 FROM vendor_profiles 
      WHERE id = vendor_featured_posts.vendor_id 
      AND user_id = auth.uid()
    )
  );
