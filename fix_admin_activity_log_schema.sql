-- Fix admin_activity_log schema

-- 1. Ensure table exists
CREATE TABLE IF NOT EXISTS public.admin_activity_log (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid()
);

-- 2. Add missing columns (Postgres doesn't support IF NOT EXISTS for ADD COLUMN nicely in one block without DO block, so we use separate statements or a safer block approach)

DO $$
BEGIN
    -- title
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'admin_activity_log' AND column_name = 'title') THEN
        ALTER TABLE public.admin_activity_log ADD COLUMN title TEXT;
    END IF;

    -- description (was subtitle in some versions)
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'admin_activity_log' AND column_name = 'description') THEN
        ALTER TABLE public.admin_activity_log ADD COLUMN description TEXT;
    END IF;

    -- activity_type
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'admin_activity_log' AND column_name = 'activity_type') THEN
        ALTER TABLE public.admin_activity_log ADD COLUMN activity_type TEXT;
    END IF;

    -- action
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'admin_activity_log' AND column_name = 'action') THEN
        ALTER TABLE public.admin_activity_log ADD COLUMN action TEXT;
    END IF;

    -- actor
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'admin_activity_log' AND column_name = 'actor') THEN
        ALTER TABLE public.admin_activity_log ADD COLUMN actor UUID REFERENCES auth.users(id);
    END IF;

    -- created_at
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'admin_activity_log' AND column_name = 'created_at') THEN
        ALTER TABLE public.admin_activity_log ADD COLUMN created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();
    END IF;
END $$;

-- 3. Migrate data if needed (e.g. if 'type' column existed instead of 'activity_type')
DO $$
BEGIN
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'admin_activity_log' AND column_name = 'type') THEN
        UPDATE public.admin_activity_log SET activity_type = type WHERE activity_type IS NULL;
        -- Optional: drop 'type' column if you want to clean up, but safer to keep for now
    END IF;

    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'admin_activity_log' AND column_name = 'subtitle') THEN
        UPDATE public.admin_activity_log SET description = subtitle WHERE description IS NULL;
    END IF;
END $$;

-- 4. Enable RLS
ALTER TABLE public.admin_activity_log ENABLE ROW LEVEL SECURITY;

-- 5. Update policies
DROP POLICY IF EXISTS "Admin can view activity logs" ON public.admin_activity_log;
CREATE POLICY "Admin can view activity logs" ON public.admin_activity_log
    FOR SELECT USING (auth.jwt() ->> 'role' = 'admin' OR EXISTS (SELECT 1 FROM admin_user WHERE id = auth.uid()));

DROP POLICY IF EXISTS "Admin can insert activity logs" ON public.admin_activity_log;
CREATE POLICY "Admin can insert activity logs" ON public.admin_activity_log
    FOR INSERT WITH CHECK (auth.jwt() ->> 'role' = 'admin' OR EXISTS (SELECT 1 FROM admin_user WHERE id = auth.uid()));
