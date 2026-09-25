-- ===========================================
-- RLS RECURSION FIX
-- ===========================================
-- This script fixes the "infinite recursion" error by using a security definer function
-- for role checks, decoupling table access from policy evaluation.

-- 1. Create a security definer function to check admin status
-- This function runs with the privileges of the creator (postgres)
-- and ignores RLS on the tables it queries internally.
CREATE OR REPLACE FUNCTION public.is_admin(user_uuid UUID)
RETURNS BOOLEAN AS $$
BEGIN
    RETURN EXISTS (
        SELECT 1 FROM public.users
        WHERE id = user_uuid AND role = 'admin'
    );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Update admin_user policies to use the helper function
ALTER TABLE admin_user ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can manage admin list" ON admin_user;
CREATE POLICY "Admins can manage admin list" ON admin_user
    FOR ALL USING (
        id = auth.uid() OR public.is_admin(auth.uid())
    );

-- 3. Update customer_user policies
ALTER TABLE customer_user ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can view all customers" ON customer_user;
CREATE POLICY "Admins can view all customers" ON customer_user
    FOR SELECT USING (public.is_admin(auth.uid()));

-- 4. Update vendor_user policies
ALTER TABLE vendor_user ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS "Admins can view all vendors" ON vendor_user;
CREATE POLICY "Admins can view all vendors" ON vendor_user
    FOR SELECT USING (public.is_admin(auth.uid()));

-- 5. Update other protected tables
-- bookings
DROP POLICY IF EXISTS "Admins can view all bookings" ON bookings;
CREATE POLICY "Admins can view all bookings" ON bookings
    FOR SELECT USING (public.is_admin(auth.uid()));

-- payments
DROP POLICY IF EXISTS "Admins can view all payments" ON payments;
CREATE POLICY "Admins can view all payments" ON payments
    FOR SELECT USING (public.is_admin(auth.uid()));

-- audit_logs
DROP POLICY IF EXISTS "Admins can view all audit logs" ON audit_logs;
CREATE POLICY "Admins can view all audit logs" ON audit_logs
    FOR SELECT USING (public.is_admin(auth.uid()));

COMMIT;
