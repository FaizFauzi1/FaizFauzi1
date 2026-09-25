-- Add portfolio column to vendor_profiles table
ALTER TABLE public.vendor_profiles
ADD COLUMN IF NOT EXISTS portfolio text[] DEFAULT '{}';

-- Grant permissions if necessary (usually implicit for owner, but good practice)
GRANT ALL ON TABLE public.vendor_profiles TO authenticated;
GRANT ALL ON TABLE public.vendor_profiles TO service_role;
