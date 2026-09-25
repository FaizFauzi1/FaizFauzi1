-- EventEase Multi-Type Referral System
-- Supports: customer, vendor, wedding_organizer, influencer, event_crew, marketplace

-- ===========================================
-- USER ATTRIBUTION COLUMNS
-- ===========================================

ALTER TABLE users ADD COLUMN IF NOT EXISTS referral_code TEXT UNIQUE;
ALTER TABLE users ADD COLUMN IF NOT EXISTS referred_by UUID REFERENCES auth.users(id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_users_referral_code ON users(referral_code);
CREATE INDEX IF NOT EXISTS idx_users_referred_by ON users(referred_by);

-- ===========================================
-- WALLET (if not yet migrated)
-- ===========================================

CREATE TABLE IF NOT EXISTS wallet (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    balance DECIMAL(10,2) DEFAULT 0.00,
    currency TEXT DEFAULT 'MYR',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(user_id)
);

CREATE TABLE IF NOT EXISTS wallet_transactions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    wallet_id UUID NOT NULL REFERENCES wallet(id) ON DELETE CASCADE,
    transaction_type TEXT NOT NULL CHECK (transaction_type IN ('credit', 'debit', 'refund', 'reward', 'purchase')),
    amount DECIMAL(10,2) NOT NULL,
    balance_before DECIMAL(10,2) NOT NULL,
    balance_after DECIMAL(10,2) NOT NULL,
    reference_type TEXT,
    reference_id UUID,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===========================================
-- PROGRAM CONFIGURATION (per referral type)
-- ===========================================

CREATE TABLE IF NOT EXISTS referral_program_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    program_type TEXT NOT NULL CHECK (program_type IN (
        'customer', 'vendor', 'wedding_organizer', 'influencer', 'event_crew', 'marketplace'
    )),
    name TEXT NOT NULL,
    description TEXT,
    referrer_role TEXT NOT NULL,
    referee_role TEXT,
    reward_type TEXT NOT NULL CHECK (reward_type IN (
        'credit', 'cashback', 'cash', 'ad_credits', 'premium_listing',
        'commission', 'lower_fee', 'voucher', 'lucky_draw'
    )),
    referrer_reward_amount DECIMAL(10,2) DEFAULT 0,
    referee_reward_amount DECIMAL(10,2) DEFAULT 0,
    commission_rate DECIMAL(5,2),
    qualifying_event TEXT NOT NULL CHECK (qualifying_event IN (
        'signup', 'profile_complete', 'first_booking', 'vendor_subscription',
        'three_shifts', 'min_earnings'
    )),
    min_referrals_for_bonus INTEGER,
    bonus_reward_amount DECIMAL(10,2),
    is_active BOOLEAN DEFAULT true,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    UNIQUE(program_type)
);

-- ===========================================
-- REFERRAL TRACKING
-- ===========================================

CREATE TABLE IF NOT EXISTS referrals (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    program_type TEXT NOT NULL CHECK (program_type IN (
        'customer', 'vendor', 'wedding_organizer', 'influencer', 'event_crew', 'marketplace'
    )),
    referrer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    referred_user_id UUID REFERENCES auth.users(id) ON DELETE SET NULL,
    referral_code TEXT NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'qualified', 'rewarded', 'expired', 'rejected')),
    qualifying_event TEXT,
    referrer_reward_amount DECIMAL(10,2),
    referee_reward_amount DECIMAL(10,2),
    qualified_at TIMESTAMPTZ,
    rewarded_at TIMESTAMPTZ,
    expires_at TIMESTAMPTZ,
    metadata JSONB DEFAULT '{}',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_referrals_referrer ON referrals(referrer_id);
CREATE INDEX IF NOT EXISTS idx_referrals_referred ON referrals(referred_user_id);
CREATE INDEX IF NOT EXISTS idx_referrals_code ON referrals(referral_code);
CREATE INDEX IF NOT EXISTS idx_referrals_status ON referrals(status);

-- ===========================================
-- REWARDS
-- ===========================================

CREATE TABLE IF NOT EXISTS referral_rewards (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referral_id UUID REFERENCES referrals(id) ON DELETE SET NULL,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    reward_type TEXT NOT NULL,
    reward_amount DECIMAL(10,2) NOT NULL,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'paid', 'cancelled')),
    payout_method TEXT CHECK (payout_method IN ('wallet', 'bank_transfer', 'ad_credits', 'premium_listing')),
    paid_at TIMESTAMPTZ,
    reference_type TEXT,
    reference_id UUID,
    description TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_referral_rewards_user ON referral_rewards(user_id);

-- ===========================================
-- INFLUENCER / LINK CLICK TRACKING
-- ===========================================

CREATE TABLE IF NOT EXISTS referral_clicks (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referral_code TEXT NOT NULL,
    referrer_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    clicked_at TIMESTAMPTZ DEFAULT NOW(),
    user_agent TEXT,
    ip_hash TEXT
);

CREATE INDEX IF NOT EXISTS idx_referral_clicks_code ON referral_clicks(referral_code);

-- ===========================================
-- FRAUD FLAGS (referral-specific)
-- ===========================================

CREATE TABLE IF NOT EXISTS referral_fraud_flags (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    referral_id UUID REFERENCES referrals(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE,
    flag_type TEXT NOT NULL CHECK (flag_type IN (
        'self_referral', 'duplicate_device', 'suspicious_pattern', 'manual_review'
    )),
    severity TEXT DEFAULT 'medium' CHECK (severity IN ('low', 'medium', 'high')),
    notes TEXT,
    resolved BOOLEAN DEFAULT false,
    resolved_by UUID REFERENCES auth.users(id),
    resolved_at TIMESTAMPTZ,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ===========================================
-- HELPER FUNCTIONS
-- ===========================================

CREATE OR REPLACE FUNCTION generate_referral_code(p_user_id UUID, p_prefix TEXT DEFAULT 'EE')
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_code TEXT;
    v_exists BOOLEAN;
BEGIN
    LOOP
        v_code := p_prefix || UPPER(SUBSTRING(REPLACE(p_user_id::TEXT, '-', ''), 1, 6));
        SELECT EXISTS(SELECT 1 FROM users WHERE referral_code = v_code) INTO v_exists;
        EXIT WHEN NOT v_exists;
        v_code := p_prefix || UPPER(SUBSTRING(MD5(RANDOM()::TEXT), 1, 8));
    END LOOP;
    RETURN v_code;
END;
$$;

CREATE OR REPLACE FUNCTION ensure_user_referral_code()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.referral_code IS NULL OR NEW.referral_code = '' THEN
        NEW.referral_code := generate_referral_code(NEW.id);
    END IF;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_users_referral_code ON users;
CREATE TRIGGER trg_users_referral_code
    BEFORE INSERT OR UPDATE OF referral_code ON users
    FOR EACH ROW
    EXECUTE FUNCTION ensure_user_referral_code();

CREATE OR REPLACE FUNCTION ensure_user_wallet()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO wallet (user_id) VALUES (NEW.id)
    ON CONFLICT (user_id) DO NOTHING;
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_users_wallet ON users;
CREATE TRIGGER trg_users_wallet
    AFTER INSERT ON users
    FOR EACH ROW
    EXECUTE FUNCTION ensure_user_wallet();

CREATE OR REPLACE FUNCTION credit_wallet(
    p_user_id UUID,
    p_amount DECIMAL,
    p_reference_type TEXT DEFAULT NULL,
    p_reference_id UUID DEFAULT NULL,
    p_description TEXT DEFAULT NULL
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_wallet_id UUID;
    v_balance_before DECIMAL;
    v_balance_after DECIMAL;
    v_tx_id UUID;
BEGIN
    INSERT INTO wallet (user_id) VALUES (p_user_id)
    ON CONFLICT (user_id) DO NOTHING;

    SELECT id, balance INTO v_wallet_id, v_balance_before
    FROM wallet WHERE user_id = p_user_id FOR UPDATE;

    v_balance_after := v_balance_before + p_amount;

    UPDATE wallet SET balance = v_balance_after, updated_at = NOW()
    WHERE id = v_wallet_id;

    INSERT INTO wallet_transactions (
        wallet_id, transaction_type, amount, balance_before, balance_after,
        reference_type, reference_id, description
    ) VALUES (
        v_wallet_id, 'reward', p_amount, v_balance_before, v_balance_after,
        p_reference_type, p_reference_id, p_description
    ) RETURNING id INTO v_tx_id;

    RETURN v_tx_id;
END;
$$;

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
    v_program referral_program_configs%ROWTYPE;
    v_referral_id UUID;
    v_program_type TEXT;
BEGIN
    IF p_referral_code IS NULL OR TRIM(p_referral_code) = '' THEN
        RETURN NULL;
    END IF;

    SELECT id, role INTO v_referrer_id, v_referrer_role
    FROM users
    WHERE UPPER(referral_code) = UPPER(TRIM(p_referral_code))
    LIMIT 1;

    IF v_referrer_id IS NULL OR v_referrer_id = p_referred_user_id THEN
        RETURN NULL;
    END IF;

    UPDATE users SET referred_by = v_referrer_id WHERE id = p_referred_user_id;

    v_program_type := CASE v_referrer_role
        WHEN 'vendor' THEN 'vendor'
        WHEN 'organizer' THEN 'wedding_organizer'
        WHEN 'customer' THEN 'customer'
        ELSE 'customer'
    END;

    SELECT * INTO v_program
    FROM referral_program_configs
    WHERE program_type = v_program_type AND is_active = true
    LIMIT 1;

    INSERT INTO referrals (
        program_type, referrer_id, referred_user_id, referral_code,
        qualifying_event, referrer_reward_amount, referee_reward_amount,
        expires_at
    ) VALUES (
        v_program_type, v_referrer_id, p_referred_user_id, UPPER(TRIM(p_referral_code)),
        COALESCE(v_program.qualifying_event, 'signup'),
        COALESCE(v_program.referrer_reward_amount, 0),
        COALESCE(v_program.referee_reward_amount, 0),
        NOW() + INTERVAL '90 days'
    ) RETURNING id INTO v_referral_id;

    RETURN v_referral_id;
END;
$$;

CREATE OR REPLACE FUNCTION qualify_referral(
    p_referred_user_id UUID,
    p_qualifying_event TEXT
)
RETURNS VOID
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_ref referrals%ROWTYPE;
BEGIN
    SELECT * INTO v_ref
    FROM referrals
    WHERE referred_user_id = p_referred_user_id
      AND status = 'pending'
      AND (qualifying_event = p_qualifying_event OR qualifying_event IS NULL)
    ORDER BY created_at DESC
    LIMIT 1;

    IF v_ref.id IS NULL THEN
        RETURN;
    END IF;

    UPDATE referrals
    SET status = 'qualified', qualified_at = NOW(), updated_at = NOW()
    WHERE id = v_ref.id;

    IF v_ref.referrer_reward_amount > 0 THEN
        INSERT INTO referral_rewards (
            referral_id, user_id, reward_type, reward_amount, status, payout_method, description
        ) VALUES (
            v_ref.id, v_ref.referrer_id, 'credit', v_ref.referrer_reward_amount,
            'pending', 'wallet', 'Referral reward for ' || p_qualifying_event
        );
    END IF;

    IF v_ref.referee_reward_amount > 0 THEN
        INSERT INTO referral_rewards (
            referral_id, user_id, reward_type, reward_amount, status, payout_method, description
        ) VALUES (
            v_ref.id, v_ref.referred_user_id, 'credit', v_ref.referee_reward_amount,
            'pending', 'wallet', 'Welcome reward for joining via referral'
        );
    END IF;
END;
$$;

CREATE OR REPLACE FUNCTION pay_referral_reward(p_reward_id UUID)
RETURNS BOOLEAN
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_reward referral_rewards%ROWTYPE;
BEGIN
    SELECT * INTO v_reward FROM referral_rewards WHERE id = p_reward_id FOR UPDATE;

    IF v_reward.id IS NULL OR v_reward.status != 'pending' THEN
        RETURN false;
    END IF;

    IF v_reward.payout_method = 'wallet' THEN
        PERFORM credit_wallet(
            v_reward.user_id, v_reward.reward_amount,
            'referral_reward', v_reward.id,
            v_reward.description
        );
    END IF;

    UPDATE referral_rewards SET status = 'paid', paid_at = NOW() WHERE id = p_reward_id;

    IF v_reward.referral_id IS NOT NULL THEN
        UPDATE referrals SET status = 'rewarded', rewarded_at = NOW(), updated_at = NOW()
        WHERE id = v_reward.referral_id AND status = 'qualified';
    END IF;

    RETURN true;
END;
$$;

-- ===========================================
-- SEED DEFAULT PROGRAMS (priority 4)
-- ===========================================

INSERT INTO referral_program_configs (
    program_type, name, description, referrer_role, referee_role,
    reward_type, referrer_reward_amount, referee_reward_amount,
    commission_rate, qualifying_event, min_referrals_for_bonus, bonus_reward_amount
) VALUES
(
    'vendor', 'Vendor Referral Program',
    'Invite another vendor. Earn RM100 cash + RM200 ad credits after they complete profile and get first booking.',
    'vendor', 'vendor', 'cash', 100.00, 0.00, NULL, 'first_booking', NULL, NULL
),
(
    'wedding_organizer', 'Wedding Organizer Affiliate',
    'Refer vendors to EventEase. Earn 10% commission when they subscribe to Premium Vendor Plan.',
    'organizer', 'vendor', 'commission', 0.00, 0.00, 10.00, 'vendor_subscription', 50, 500.00
),
(
    'influencer', 'Influencer Affiliate Program',
    'Share your promo code. Earn RM30 per successful booking. Referees get RM100 voucher.',
    'customer', 'customer', 'cash', 30.00, 100.00, NULL, 'first_booking', NULL, NULL
),
(
    'customer', 'Customer Referral Program',
    'Invite friends who book vendors. Earn RM20 EventEase credits per successful referral.',
    'customer', 'customer', 'credit', 20.00, 10.00, NULL, 'first_booking', 5, 100.00
),
(
    'marketplace', 'Marketplace Referral',
    'Bring your own customers to EventEase. Lower platform fee on referred bookings.',
    'vendor', 'customer', 'lower_fee', 0.00, 0.00, NULL, 'first_booking', NULL, NULL
),
(
    'event_crew', 'Event Crew Referral',
    'Refer crew members. Earn reward after they complete 3 shifts or RM300 earnings.',
    'customer', 'customer', 'credit', 50.00, 25.00, NULL, 'three_shifts', NULL, NULL
)
ON CONFLICT (program_type) DO NOTHING;

-- Backfill referral codes for existing users
UPDATE users SET referral_code = generate_referral_code(id)
WHERE referral_code IS NULL OR referral_code = '';

-- ===========================================
-- ROW LEVEL SECURITY
-- ===========================================

ALTER TABLE referral_program_configs ENABLE ROW LEVEL SECURITY;
ALTER TABLE referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_rewards ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_clicks ENABLE ROW LEVEL SECURITY;
ALTER TABLE referral_fraud_flags ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet ENABLE ROW LEVEL SECURITY;
ALTER TABLE wallet_transactions ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can read active referral configs"
    ON referral_program_configs FOR SELECT
    USING (is_active = true);

CREATE POLICY "Admins manage referral configs"
    ON referral_program_configs FOR ALL
    USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')));

CREATE POLICY "Users view own referrals as referrer"
    ON referrals FOR SELECT
    USING (referrer_id = auth.uid() OR referred_user_id = auth.uid());

CREATE POLICY "Admins view all referrals"
    ON referrals FOR SELECT
    USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')));

CREATE POLICY "System inserts referrals"
    ON referrals FOR INSERT
    WITH CHECK (referrer_id = auth.uid() OR referred_user_id = auth.uid());

CREATE POLICY "Users view own rewards"
    ON referral_rewards FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Admins manage rewards"
    ON referral_rewards FOR ALL
    USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')));

CREATE POLICY "Anyone can log referral clicks"
    ON referral_clicks FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Referrers view own clicks"
    ON referral_clicks FOR SELECT
    USING (referrer_id = auth.uid());

CREATE POLICY "Admins view all clicks"
    ON referral_clicks FOR SELECT
    USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')));

CREATE POLICY "Admins manage fraud flags"
    ON referral_fraud_flags FOR ALL
    USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')));

CREATE POLICY "Users view own wallet"
    ON wallet FOR SELECT
    USING (user_id = auth.uid());

CREATE POLICY "Users view own wallet transactions"
    ON wallet_transactions FOR SELECT
    USING (EXISTS (SELECT 1 FROM wallet w WHERE w.id = wallet_id AND w.user_id = auth.uid()));

CREATE POLICY "Admins view all wallets"
    ON wallet FOR SELECT
    USING (EXISTS (SELECT 1 FROM users WHERE id = auth.uid() AND role IN ('admin', 'super_admin')));
