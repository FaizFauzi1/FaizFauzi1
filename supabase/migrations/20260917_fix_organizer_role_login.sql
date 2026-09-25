-- Organizer sign-in was resolving as customer because:
-- 1) create_user_profile() never handled role = organizer (inserted customer_user)
-- 2) login read customer_user.role and ignored users.role / organizer_user

ALTER TABLE public.users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE public.users ADD CONSTRAINT users_role_check
    CHECK (role IN ('admin', 'super_admin', 'vendor', 'customer', 'organizer'));

CREATE TABLE IF NOT EXISTS public.organizer_user (
    id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
    name TEXT NOT NULL,
    email TEXT,
    phone TEXT,
    role TEXT DEFAULT 'organizer' CHECK (role = 'organizer'),
    status TEXT DEFAULT 'active' CHECK (status IN ('active', 'inactive', 'banned', 'pending')),
    company_name TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE public.organizer_user ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Organizers can view own profile" ON public.organizer_user;
CREATE POLICY "Organizers can view own profile" ON public.organizer_user
    FOR SELECT USING (id = auth.uid());

DROP POLICY IF EXISTS "Organizers can update own profile" ON public.organizer_user;
CREATE POLICY "Organizers can update own profile" ON public.organizer_user
    FOR UPDATE USING (id = auth.uid());

DROP POLICY IF EXISTS "Users insert own organizer profile" ON public.organizer_user;
CREATE POLICY "Users insert own organizer profile" ON public.organizer_user
    FOR INSERT TO authenticated
    WITH CHECK (id = auth.uid());

DROP POLICY IF EXISTS "Admins manage organizer users" ON public.organizer_user;
CREATE POLICY "Admins manage organizer users" ON public.organizer_user
    FOR ALL USING (
        EXISTS (
            SELECT 1 FROM public.users
            WHERE id = auth.uid() AND role IN ('admin', 'super_admin')
        )
        OR EXISTS (
            SELECT 1 FROM public.admin_user WHERE id = auth.uid()
        )
    );

-- Repair known organizer demo/account + anyone who owns an organizer company
UPDATE public.users u
SET role = 'organizer',
    updated_at = NOW()
WHERE u.id = '2fcd6641-e4cd-47be-b7ad-a916ae5d1627'
   OR lower(u.email) = 'organizer1@eventease.com'
   OR EXISTS (
        SELECT 1 FROM public.organizer_user ou WHERE ou.id = u.id
   );

DO $$
BEGIN
    IF to_regclass('public.organizer_companies') IS NOT NULL THEN
        UPDATE public.users u
        SET role = 'organizer',
            updated_at = NOW()
        WHERE EXISTS (
            SELECT 1 FROM public.organizer_companies c
            WHERE c.owner_user_id = u.id
        );
    END IF;
END $$;

INSERT INTO public.organizer_user (id, name, email, phone, role, status)
SELECT
    u.id,
    COALESCE(cu.name, split_part(COALESCE(u.email, 'organizer'), '@', 1)),
    u.email,
    COALESCE(cu.phone, ''),
    'organizer',
    'active'
FROM public.users u
LEFT JOIN public.customer_user cu ON cu.id = u.id
WHERE u.role = 'organizer'
ON CONFLICT (id) DO UPDATE
SET role = 'organizer',
    status = 'active',
    email = EXCLUDED.email,
    updated_at = NOW();

DELETE FROM public.customer_user
WHERE id IN (SELECT id FROM public.users WHERE role = 'organizer');

CREATE OR REPLACE FUNCTION public.create_user_profile()
RETURNS TRIGGER AS $$
DECLARE
    v_role TEXT := COALESCE(NEW.raw_user_meta_data->>'role', 'customer');
    v_name TEXT := COALESCE(NEW.raw_user_meta_data->>'name', split_part(COALESCE(NEW.email, 'user'), '@', 1));
    v_phone TEXT := COALESCE(NEW.raw_user_meta_data->>'phone', '');
BEGIN
    INSERT INTO public.users (id, email, role)
    VALUES (NEW.id, NEW.email, v_role)
    ON CONFLICT (id) DO UPDATE SET email = EXCLUDED.email;

    IF v_role = 'admin' OR v_role = 'super_admin' THEN
        INSERT INTO public.admin_user (id, name, email, phone)
        VALUES (NEW.id, v_name, NEW.email, v_phone)
        ON CONFLICT (id) DO NOTHING;
    ELSIF v_role = 'vendor' THEN
        INSERT INTO public.vendor_user (id, name, email, phone)
        VALUES (NEW.id, v_name, NEW.email, v_phone)
        ON CONFLICT (id) DO NOTHING;
    ELSIF v_role = 'organizer' THEN
        INSERT INTO public.organizer_user (id, name, email, phone, role, status)
        VALUES (NEW.id, v_name, NEW.email, v_phone, 'organizer', 'active')
        ON CONFLICT (id) DO NOTHING;
    ELSE
        INSERT INTO public.customer_user (id, name, email, phone)
        VALUES (NEW.id, v_name, NEW.email, v_phone)
        ON CONFLICT (id) DO NOTHING;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;
