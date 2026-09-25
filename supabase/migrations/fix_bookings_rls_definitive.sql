-- =============================================
-- FIX: DEFINITIVE BOOKINGS RLS POLICIES
-- =============================================

-- 1. Ensure RLS is enabled
ALTER TABLE public.bookings ENABLE ROW LEVEL SECURITY;

-- 2. Clean up existing policies to avoid conflicts
DROP POLICY IF EXISTS "Admins can view all bookings" ON public.bookings;
DROP POLICY IF EXISTS "Vendors can view own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Customers can view own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Customers can create own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Customers can update own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Vendors can update own bookings" ON public.bookings;
DROP POLICY IF EXISTS "Admins can manage all bookings" ON public.bookings;

-- 3. SELECT POLICIES
-- Admins can view all
CREATE POLICY "Admins can view all bookings" ON public.bookings
    FOR SELECT TO authenticated
    USING (
        EXISTS (SELECT 1 FROM public.admin_user WHERE id = auth.uid()) OR
        (SELECT role FROM public.users WHERE id = auth.uid()) IN ('admin', 'super_admin')
    );

-- Vendors can view bookings for their services
CREATE POLICY "Vendors can view own bookings" ON public.bookings
    FOR SELECT TO authenticated
    USING (
        vendor_id IN (SELECT id FROM public.vendor_profiles WHERE user_id = auth.uid())
    );

-- Customers can view their own bookings
CREATE POLICY "Customers can view own bookings" ON public.bookings
    FOR SELECT TO authenticated
    USING (auth.uid() = customer_id);

-- 4. INSERT POLICIES
-- Customers can create bookings for themselves
CREATE POLICY "Customers can create own bookings" ON public.bookings
    FOR INSERT TO authenticated
    WITH CHECK (auth.uid() = customer_id);

-- Admins can create bookings for anyone
CREATE POLICY "Admins can insert bookings" ON public.bookings
    FOR INSERT TO authenticated
    WITH CHECK (
        EXISTS (SELECT 1 FROM public.admin_user WHERE id = auth.uid()) OR
        (SELECT role FROM public.users WHERE id = auth.uid()) IN ('admin', 'super_admin')
    );

-- 5. UPDATE POLICIES
-- Customers can update their own bookings (e.g., cancel)
CREATE POLICY "Customers can update own bookings" ON public.bookings
    FOR UPDATE TO authenticated
    USING (auth.uid() = customer_id)
    WITH CHECK (auth.uid() = customer_id);

-- Vendors can update status related fields for their bookings
CREATE POLICY "Vendors can update own bookings" ON public.bookings
    FOR UPDATE TO authenticated
    USING (
        vendor_id IN (SELECT id FROM public.vendor_profiles WHERE user_id = auth.uid())
    )
    WITH CHECK (
        vendor_id IN (SELECT id FROM public.vendor_profiles WHERE user_id = auth.uid())
    );

-- Admins can update any booking
CREATE POLICY "Admins can update all bookings" ON public.bookings
    FOR UPDATE TO authenticated
    USING (
        EXISTS (SELECT 1 FROM public.admin_user WHERE id = auth.uid()) OR
        (SELECT role FROM public.users WHERE id = auth.uid()) IN ('admin', 'super_admin')
    );

-- 6. DELETE POLICIES
CREATE POLICY "Admins can delete bookings" ON public.bookings
    FOR DELETE TO authenticated
    USING (
        EXISTS (SELECT 1 FROM public.admin_user WHERE id = auth.uid()) OR
        (SELECT role FROM public.users WHERE id = auth.uid()) IN ('admin', 'super_admin')
    );

-- 7. Grant access to the authenticated role
GRANT ALL ON public.bookings TO authenticated;
GRANT ALL ON public.bookings TO service_role;
