-- Phase 1 marketplace ranking: manual + simple priority (see product docs).
-- Set per row in Supabase (or via admin); app sorts by this descending.

ALTER TABLE public.vendor_profiles
  ADD COLUMN IF NOT EXISTS priority_score DOUBLE PRECISION NOT NULL DEFAULT 0;

COMMENT ON COLUMN public.vendor_profiles.priority_score IS
  'Higher = listed first (featured, promos, ecosystem balance). Tune manually early; automate later.';

CREATE INDEX IF NOT EXISTS idx_vendor_profiles_priority_score
  ON public.vendor_profiles (priority_score DESC);
