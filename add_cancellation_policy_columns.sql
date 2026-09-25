DO $$ 
BEGIN 
    -- Add cancellation_policy column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vendor_services' AND column_name = 'cancellation_policy') THEN 
        ALTER TABLE vendor_services ADD COLUMN cancellation_policy TEXT; 
    END IF;

    -- Add cancellation_policy_type column if it doesn't exist
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name = 'vendor_services' AND column_name = 'cancellation_policy_type') THEN 
        ALTER TABLE vendor_services ADD COLUMN cancellation_policy_type TEXT DEFAULT 'platform'; 
    END IF;
END $$;
