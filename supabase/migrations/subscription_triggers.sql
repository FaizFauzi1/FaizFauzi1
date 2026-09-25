-- Subscription Payment Completion Trigger
-- This script handles automatic tier updates and notifications when a payment is marked 'completed'

-- 1. Create the function to handle subscription updates
CREATE OR REPLACE FUNCTION handle_subscription_payment_completion()
RETURNS TRIGGER AS $$
DECLARE
    new_tier_name_v TEXT;
    v_user_id UUID;
    v_business_name TEXT;
    admin_id UUID;
BEGIN
    -- Only proceed if status changed to 'completed'
    IF (NEW.payment_status = 'completed' AND (OLD.payment_status IS NULL OR OLD.payment_status != 'completed')) THEN
        
        -- Get the tier name
        SELECT name INTO new_tier_name_v 
        FROM subscription_tiers 
        WHERE id = NEW.tier_id;
        
        -- Get vendor details (user_id for notifications)
        SELECT user_id, business_name INTO v_user_id, v_business_name
        FROM vendor_profiles
        WHERE id = NEW.vendor_id;
        
        -- 1. Update the vendor's active tier
        UPDATE vendor_profiles
        SET subscription_tier = new_tier_name_v,
            updated_at = NOW()
        WHERE id = NEW.vendor_id;
        
        -- 2. Notify the Vendor
        INSERT INTO notifications (user_id, title, message, type)
        VALUES (
            v_user_id,
            'Subscription Upgraded!',
            'Your account has been successfully upgraded to the ' || COALESCE(new_tier_name_v, 'new') || ' plan. Enjoy your new features!',
            'subscription'
        );
        
        -- 3. Notify Admins
        FOR admin_id IN (SELECT id FROM admin_user) LOOP
            INSERT INTO notifications (user_id, title, message, type)
            VALUES (
                admin_id,
                'New Subscription Payment',
                'Vendor ' || COALESCE(v_business_name, 'Unknown') || ' has upgraded to ' || COALESCE(new_tier_name_v, 'new tier') || ' (RM ' || NEW.amount || ').',
                'admin_alert'
            );
        END LOOP;
        
    END IF;
    
    RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 2. Create the trigger
DROP TRIGGER IF EXISTS on_subscription_payment_completed ON subscription_payments;
CREATE TRIGGER on_subscription_payment_completed
    AFTER UPDATE ON subscription_payments
    FOR EACH ROW
    EXECUTE FUNCTION handle_subscription_payment_completion();

-- Ensure subscription_tier column exists in vendor_profiles (adding safely)
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='vendor_profiles' AND column_name='subscription_tier') THEN
        ALTER TABLE vendor_profiles ADD COLUMN subscription_tier TEXT DEFAULT 'starter';
    END IF;
END $$;
