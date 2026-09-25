-- 1. Add Soft Delete support to users table
ALTER TABLE public.users ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMP WITH TIME ZONE;

-- 2. Create User Sessions table for Device Management
CREATE TABLE IF NOT EXISTS public.user_sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    device_name TEXT,
    platform TEXT,
    last_active_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    session_id TEXT NOT NULL, -- Stores Supabase session ID
    UNIQUE(user_id, session_id)
);

-- 3. Create Security Logs table
CREATE TABLE IF NOT EXISTS public.security_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    event_type TEXT NOT NULL, -- 'login', 'password_change', 'mfa_enabled', 'account_deleted', etc.
    description TEXT,
    ip_address TEXT,
    user_agent TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 4. Enable RLS
ALTER TABLE public.user_sessions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.security_logs ENABLE ROW LEVEL SECURITY;

-- 5. RLS Policies for user_sessions
DROP POLICY IF EXISTS "Users can manage their own sessions" ON public.user_sessions;
CREATE POLICY "Users can manage their own sessions"
ON public.user_sessions
FOR ALL
USING (auth.uid() = user_id);

-- 6. RLS Policies for security_logs
DROP POLICY IF EXISTS "Users can view their own security logs" ON public.security_logs;
CREATE POLICY "Users can view their own security logs"
ON public.security_logs
FOR SELECT
USING (auth.uid() = user_id);

DROP POLICY IF EXISTS "System/Users can insert security logs" ON public.security_logs;
CREATE POLICY "System/Users can insert security logs"
ON public.security_logs
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- 7. Function to automatically track session updates
CREATE OR REPLACE FUNCTION public.update_session_activity()
RETURNS TRIGGER AS $$
BEGIN
    NEW.last_active_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_session_activity
BEFORE UPDATE ON public.user_sessions
FOR EACH ROW
EXECUTE FUNCTION public.update_session_activity();
