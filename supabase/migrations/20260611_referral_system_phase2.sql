-- EventEase Referral System Phase 2
-- Qualification triggers, organizer role, custom codes, marketplace fees, recurring commission

-- ===========================================
-- ORGANIZER ROLE + organizer_user TABLE
-- ===========================================

ALTER TABLE users DROP CONSTRAINT IF EXISTS users_role_check;
ALTER TABLE users ADD CONSTRAINT users_role_check
    CHECK (role IN ('admin', 'super_admin', 'vendor', 'customer', 'organizer'));

CREATE TABLE IF NOT EXISTS organizer_user (
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

ALTER TABLE organizer_user ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Organizers can view own profile" ON organizer_user
    FOR SELECT USING (id = auth.uid());

CREATE POLICY "Organizers can update own profile" ON organizer_user
    FOR UPDATE USING (id = auth.uid());

CREATE POLICY "Admins manage organizer users" ON organizer_user
    FOR ALL USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
    );

-- ===========================================
-- CUSTOM / INFLUENCER PROMO CODES
-- ===========================================

CREATE TABLE IF NOT EXISTS referral_custom_codes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    custom_code TEXT NOT NULL,
    program_type TEXT NOT NULL CHECK (program_type IN (
        'customer', 'vendor', 'wedding_organizer', 'influencer', 'event_crew', 'marketplace'
    )),
    referee_discount_amount DECIMAL(10,2) DEFAULT 0,
    referrer_reward_amount DECIMAL(10,2),
    is_active BOOLEAN DEFAULT true,
    max_uses INTEGER,
    use_count INTEGER DEFAULT 0,
    expires_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(custom_code)
);

CREATE INDEX IF NOT EXISTS idx_referral_custom_codes_user ON referral_custom_codes(user_id);
CREATE INDEX IF NOT EXISTS idx_referral_custom_codes_code ON referral_custom_codes(UPPER(custom_code));

ALTER TABLE referral_custom_codes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users manage own custom codes" ON referral_custom_codes
    FOR ALL USING (user_id = auth.uid());

CREATE POLICY "Anyone can read active custom codes" ON referral_custom_codes
    FOR SELECT USING (is_active = true);

CREATE POLICY "Admins manage all custom codes" ON referral_custom_codes
    FOR ALL USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
    );

-- ===========================================
-- RECURRING ORGANIZER COMMISSION LOG
-- ===========================================

CREATE TABLE IF NOT EXISTS referral_commission_payments (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referral_id UUID NOT NULL REFERENCES referrals(id) ON DELETE CASCADE,
    organizer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    vendor_user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    subscription_payment_id UUID,
    subscription_amount DECIMAL(10,2) NOT NULL,
    commission_rate DECIMAL(5,2) NOT NULL,
    commission_amount DECIMAL(10,2) NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'cancelled')),
    paid_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_referral_commission_organizer ON referral_commission_payments(organizer_id);

ALTER TABLE referral_commission_payments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Organizers view own commissions" ON referral_commission_payments
    FOR SELECT USING (organizer_id = auth.uid());

CREATE POLICY "Admins manage commissions" ON referral_commission_payments
    FOR ALL USING (
        EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'super_admin'))
    );

-- ===========================================
-- UPDATE apply_referral_on_signup (custom codes)
-- ===========================================

CREATE OR REPLACE FUNCTION apply_referral_on_signup(
    p_referred_user_id UUID,
    p_referral_code TEXT
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_referrer_id UUID;
    v_referrer_role TEXT;
    v_referee_role TEXT;
    v_program referral_program_configs%ROWTYPE;
    v_referral_id UUID;
    v_program_type TEXT;
    v_custom referral_custom_codes%ROWTYPE;
    v_code TEXT;
    v_referee_reward DECIMAL(10,2);
    v_referrer_reward DECIMAL(10,2);
BEGIN
    IF p_referral_code IS NULL OR TRIM(p_referral_code) = '' THEN
        RETURN NULL;
    END IF;

    v_code := UPPER(TRIM(p_referral_code));

    -- 1. Check custom / influencer codes first
    SELECT * INTO v_custom
    FROM referral_custom_codes
    WHERE UPPER(custom_code) = v_code
      AND is_active = true
      AND (expires_at IS NULL OR expires_at > NOW())
      AND (max_uses IS NULL OR use_count < max_uses)
    LIMIT 1;

    IF v_custom.id IS NOT NULL THEN
        v_referrer_id := v_custom.user_id;

        SELECT role INTO v_referrer_role FROM users WHERE id = v_referrer_id;

        IF v_referrer_id = p_referred_user_id THEN
            RETURN NULL;
        END IF;

        UPDATE users SET referred_by = v_referrer_id WHERE id = p_referred_user_id;

        UPDATE referral_custom_codes
        SET use_count = use_count + 1, updated_at = NOW()
        WHERE id = v_custom.id;

        SELECT * INTO v_program
        FROM referral_program_configs
        WHERE program_type = v_custom.program_type AND is_active = true
        LIMIT 1;

        v_referrer_reward := COALESCE(v_custom.referrer_reward_amount, v_program.referrer_reward_amount, 0);
        v_referee_reward := COALESCE(v_custom.referee_discount_amount, v_program.referee_reward_amount, 0);

        INSERT INTO referrals (
            program_type, referrer_id, referred_user_id, referral_code,
            qualifying_event, referrer_reward_amount, referee_reward_amount,
            expires_at, metadata
        ) VALUES (
            v_custom.program_type, v_referrer_id, p_referred_user_id, v_code,
            COALESCE(v_program.qualifying_event, 'first_booking'),
            v_referrer_reward, v_referee_reward,
            NOW() + INTERVAL '90 days',
            jsonb_build_object('custom_code_id', v_custom.id)
        ) RETURNING id INTO v_referral_id;

        RETURN v_referral_id;
    END IF;

    -- 2. Fall back to user referral codes
    SELECT id, role INTO v_referrer_id, v_referrer_role
    FROM users
    WHERE UPPER(referral_code) = v_code
    LIMIT 1;

    IF v_referrer_id IS NULL OR v_referrer_id = p_referred_user_id THEN
        RETURN NULL;
    END IF;

    UPDATE users SET referred_by = v_referrer_id WHERE id = p_referred_user_id;

    -- Marketplace: vendor referring customer directly
    IF v_referrer_role = 'vendor' THEN
        SELECT role INTO v_referee_role FROM users WHERE id = p_referred_user_id;
        IF v_referee_role = 'customer' THEN
            v_program_type := 'marketplace';
        ELSE
            v_program_type := 'vendor';
        END IF;
    ELSE
        v_program_type := CASE v_referrer_role
            WHEN 'organizer' THEN 'wedding_organizer'
            WHEN 'customer' THEN 'customer'
            ELSE 'customer'
        END;
    END IF;

    SELECT * INTO v_program
    FROM referral_program_configs
    WHERE program_type = v_program_type AND is_active = true
    LIMIT 1;

    INSERT INTO referrals (
        program_type, referrer_id, referred_user_id, referral_code,
        qualifying_event, referrer_reward_amount, referee_reward_amount,
        expires_at
    ) VALUES (
        v_program_type, v_referrer_id, p_referred_user_id, v_code,
        COALESCE(v_program.qualifying_event, 'signup'),
        COALESCE(v_program.referrer_reward_amount, 0),
        COALESCE(v_program.referee_reward_amount, 0),
        NOW() + INTERVAL '90 days'
    ) RETURNING id INTO v_referral_id;

    RETURN v_referral_id;
END;
$$;

-- ===========================================
-- ORGANIZER RECURRING COMMISSION ON SUBSCRIPTION
-- ===========================================

CREATE OR REPLACE FUNCTION process_organizer_subscription_commission(
    p_vendor_user_id UUID,
    p_subscription_amount DECIMAL,
    p_subscription_payment_id UUID DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_ref referrals%ROWTYPE;
    v_program referral_program_configs%ROWTYPE;
    v_commission DECIMAL(10,2);
    v_commission_id UUID;
    v_reward_id UUID;
BEGIN
    SELECT * INTO v_ref
    FROM referrals
    WHERE referred_user_id = p_vendor_user_id
      AND program_type = 'wedding_organizer'
      AND status IN ('pending', 'qualified', 'rewarded')
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_ref.id IS NULL THEN
        RETURN NULL;
    END IF;

    SELECT * INTO v_program
    FROM referral_program_configs
    WHERE program_type = 'wedding_organizer' AND is_active = true
    LIMIT 1;

    IF v_program.commission_rate IS NULL OR v_program.commission_rate <= 0 THEN
        RETURN NULL;
    END IF;

    v_commission := ROUND(p_subscription_amount * v_program.commission_rate / 100, 2);

    IF v_commission <= 0 THEN
        RETURN NULL;
    END IF;

    INSERT INTO referral_commission_payments (
        referral_id, organizer_id, vendor_user_id,
        subscription_payment_id, subscription_amount,
        commission_rate, commission_amount, status
    ) VALUES (
        v_ref.id, v_ref.referrer_id, p_vendor_user_id,
        p_subscription_payment_id, p_subscription_amount,
        v_program.commission_rate, v_commission, 'pending'
    ) RETURNING id INTO v_commission_id;

    INSERT INTO referral_rewards (
        referral_id, user_id, reward_type, reward_amount,
        status, payout_method, description, reference_type, reference_id
    ) VALUES (
        v_ref.id, v_ref.referrer_id, 'commission', v_commission,
        'pending', 'wallet',
        'Organizer commission on vendor subscription (RM' || p_subscription_amount || ')',
        'subscription_payment', p_subscription_payment_id
    ) RETURNING id INTO v_reward_id;

    -- First subscription qualifies the referral
    IF v_ref.status = 'pending' AND v_ref.qualifying_event = 'vendor_subscription' THEN
        UPDATE referrals
        SET status = 'qualified', qualified_at = NOW(), updated_at = NOW()
        WHERE id = v_ref.id;
    END IF;

    RETURN v_commission_id;
END;
$$;

-- ===========================================
-- MARKETPLACE SERVICE FEE REDUCTION
-- ===========================================

CREATE OR REPLACE FUNCTION get_customer_service_fee_rate(
    p_customer_id UUID,
    p_vendor_id UUID DEFAULT NULL
)
RETURNS DECIMAL
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_vendor_user_id UUID;
    v_default_rate DECIMAL := 0.02;
    v_reduced_rate DECIMAL := 0.01;
BEGIN
    IF p_vendor_id IS NOT NULL THEN
        SELECT user_id INTO v_vendor_user_id
        FROM vendor_profiles WHERE id = p_vendor_id;
    END IF;

    -- Customer referred by this specific vendor (marketplace program)
    IF v_vendor_user_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM referrals
        WHERE referred_user_id = p_customer_id
          AND referrer_id = v_vendor_user_id
          AND program_type = 'marketplace'
          AND status IN ('pending', 'qualified', 'rewarded')
    ) THEN
        RETURN v_reduced_rate;
    END IF;

    -- Generic referred_by vendor match
    IF v_vendor_user_id IS NOT NULL AND EXISTS (
        SELECT 1 FROM users
        WHERE id = p_customer_id
          AND referred_by = v_vendor_user_id
    ) THEN
        RETURN v_reduced_rate;
    END IF;

    RETURN v_default_rate;
END;
$$;

-- ===========================================
-- BOOKING QUALIFICATION TRIGGER
-- ===========================================

CREATE OR REPLACE FUNCTION handle_booking_referral_qualification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.customer_id IS NOT NULL
       AND NEW.status IN ('confirmed', 'completed')
       AND (OLD.status IS NULL OR OLD.status NOT IN ('confirmed', 'completed')) THEN
        PERFORM qualify_referral(NEW.customer_id, 'first_booking');
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_booking_referral_qualification ON bookings;
CREATE TRIGGER trg_booking_referral_qualification
    AFTER INSERT OR UPDATE OF status ON bookings
    FOR EACH ROW
    EXECUTE FUNCTION handle_booking_referral_qualification();

-- ===========================================
-- VENDOR PROFILE COMPLETION TRIGGER
-- ===========================================

CREATE OR REPLACE FUNCTION handle_vendor_profile_referral_qualification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.user_id IS NOT NULL
       AND NEW.profile_completion_status IN ('complete', 'pending_review', 'approved')
       AND (OLD.profile_completion_status IS NULL
            OR OLD.profile_completion_status NOT IN ('complete', 'pending_review', 'approved')) THEN
        PERFORM qualify_referral(NEW.user_id, 'profile_complete');
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_vendor_profile_referral ON vendor_profiles;
CREATE TRIGGER trg_vendor_profile_referral
    AFTER UPDATE OF profile_completion_status ON vendor_profiles
    FOR EACH ROW
    EXECUTE FUNCTION handle_vendor_profile_referral_qualification();

-- ===========================================
-- SUBSCRIPTION PAYMENT → REFERRAL HOOKS
-- ===========================================

CREATE OR REPLACE FUNCTION handle_subscription_payment_completion()
RETURNS TRIGGER AS $$
DECLARE
    new_tier_name_v TEXT;
    v_user_id UUID;
    v_business_name TEXT;
    admin_id UUID;
BEGIN
    IF (NEW.payment_status = 'completed'
        AND (OLD.payment_status IS NULL OR OLD.payment_status != 'completed')) THEN

        SELECT name INTO new_tier_name_v
        FROM subscription_tiers
        WHERE id = NEW.tier_id;

        SELECT user_id, business_name INTO v_user_id, v_business_name
        FROM vendor_profiles
        WHERE id = NEW.vendor_id;

        UPDATE vendor_profiles
        SET subscription_tier = new_tier_name_v,
            updated_at = NOW()
        WHERE id = NEW.vendor_id;

        INSERT INTO notifications (user_id, title, message, type)
        VALUES (
            v_user_id,
            'Subscription Upgraded!',
            'Your account has been successfully upgraded to the '
                || COALESCE(new_tier_name_v, 'new') || ' plan. Enjoy your new features!',
            'subscription'
        );

        FOR admin_id IN (SELECT id FROM admin_user) LOOP
            INSERT INTO notifications (user_id, title, message, type)
            VALUES (
                admin_id,
                'New Subscription Payment',
                'Vendor ' || COALESCE(v_business_name, 'Unknown')
                    || ' has upgraded to ' || COALESCE(new_tier_name_v, 'new tier')
                    || ' (RM ' || NEW.amount || ').',
                'admin_alert'
            );
        END LOOP;

        -- Referral: vendor subscription qualifies organizer affiliate + recurring commission
        IF v_user_id IS NOT NULL THEN
            PERFORM process_organizer_subscription_commission(
                v_user_id, NEW.amount, NEW.id
            );
            PERFORM qualify_referral(v_user_id, 'vendor_subscription');
        END IF;
    END IF;

    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

DROP TRIGGER IF EXISTS on_subscription_payment_completed ON subscription_payments;
CREATE TRIGGER on_subscription_payment_completed
    AFTER UPDATE ON subscription_payments
    FOR EACH ROW
    EXECUTE FUNCTION handle_subscription_payment_completion();

-- ===========================================
-- LEADERBOARD RPC
-- ===========================================

CREATE OR REPLACE FUNCTION referral_leaderboard(p_limit INTEGER DEFAULT 20)
RETURNS TABLE (
    user_id UUID,
    name TEXT,
    role TEXT,
    referral_count BIGINT,
    successful_referrals BIGINT,
    total_earned DECIMAL
)
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
    SELECT
        r.referrer_id AS user_id,
        COALESCE(cu.name, vu.name, ou.name, u.email, 'User') AS name,
        u.role,
        COUNT(r.id) AS referral_count,
        COUNT(r.id) FILTER (WHERE r.status = 'rewarded') AS successful_referrals,
        COALESCE(SUM(rr.reward_amount) FILTER (WHERE rr.status = 'paid'), 0) AS total_earned
    FROM referrals r
    JOIN users u ON u.id = r.referrer_id
    LEFT JOIN customer_user cu ON cu.id = r.referrer_id
    LEFT JOIN vendor_user vu ON vu.id = r.referrer_id
    LEFT JOIN organizer_user ou ON ou.id = r.referrer_id
    LEFT JOIN referral_rewards rr ON rr.referral_id = r.id AND rr.user_id = r.referrer_id
    GROUP BY r.referrer_id, cu.name, vu.name, ou.name, u.email, u.role
    ORDER BY successful_referrals DESC, referral_count DESC
    LIMIT p_limit;
$$;

-- Seed example influencer code (inactive template — admins/users create their own)
-- INSERT INTO referral_custom_codes (user_id, custom_code, program_type, referee_discount_amount, referrer_reward_amount)
-- VALUES (...);
