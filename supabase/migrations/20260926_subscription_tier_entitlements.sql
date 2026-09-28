ALTER TABLE public.subscription_tiers
    ADD COLUMN IF NOT EXISTS target_audience TEXT NOT NULL DEFAULT 'vendor',
    ADD COLUMN IF NOT EXISTS limits JSONB NOT NULL DEFAULT '{}'::jsonb;

UPDATE public.subscription_tiers
SET target_audience = 'vendor'
WHERE target_audience = 'all'
  AND LOWER(name) IN (
      'free', 'starter', 'basic', 'pro', 'professional',
      'business', 'premium', 'enterprise'
  );

UPDATE public.subscription_tiers
SET limits = COALESCE(limits, '{}'::jsonb) ||
    CASE
        WHEN LOWER(name) IN ('pro', 'professional') THEN jsonb_build_object(
            'max_listings', 10,
            'promo_tools', true,
            'analytics', true,
            'export_leads', false,
            'visibility_level', 'High (Featured)',
            'commission_rate_percent', 10
        )
        WHEN LOWER(name) IN ('business', 'premium', 'enterprise') THEN jsonb_build_object(
            'max_listings', -1,
            'promo_tools', true,
            'analytics', true,
            'export_leads', true,
            'visibility_level', 'Highest (Top Priority)',
            'commission_rate_percent', 7
        )
        ELSE jsonb_build_object(
            'max_listings', 3,
            'promo_tools', false,
            'analytics', false,
            'export_leads', false,
            'visibility_level', 'Standard',
            'commission_rate_percent', 12
        )
    END
WHERE LOWER(name) IN (
    'free', 'starter', 'basic', 'pro', 'professional',
    'business', 'premium', 'enterprise'
);