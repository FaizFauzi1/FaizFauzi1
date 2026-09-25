-- Fix missing columns in event_checklists table
ALTER TABLE event_checklists 
ADD COLUMN IF NOT EXISTS is_essential BOOLEAN DEFAULT false;

-- Ensure is_done exists (some schemas might have is_completed instead)
DO $$ 
BEGIN 
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='event_checklists' AND column_name='is_done') THEN
        IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='event_checklists' AND column_name='is_completed') THEN
            ALTER TABLE event_checklists RENAME COLUMN is_completed TO is_done;
        ELSE
            ALTER TABLE event_checklists ADD COLUMN is_done BOOLEAN DEFAULT false;
        END IF;
    END IF;
END $$;

-- Ensure due_date is TIMESTAMP WITH TIME ZONE if it exists as DATE
ALTER TABLE event_checklists 
ALTER COLUMN due_date TYPE TIMESTAMP WITH TIME ZONE USING due_date::timestamp with time zone;
