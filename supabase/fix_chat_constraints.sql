-- Fix Chat Message Type Check Constraint
-- Run this in your Supabase SQL Editor to allow 'quotation' message types.

DO $$ 
DECLARE 
    constraint_name TEXT;
BEGIN
    -- 1. Find the existing check constraint name for chat_messages table and message_type column
    SELECT conname INTO constraint_name
    FROM pg_constraint 
    WHERE conrelid = 'public.chat_messages'::regclass 
    AND contype = 'c' 
    AND (
        consrc LIKE '%message_type%' 
        OR 
        pg_get_constraintdef(oid) LIKE '%message_type%'
    );

    -- 2. Drop the old constraint if it exists
    IF constraint_name IS NOT NULL THEN
        EXECUTE 'ALTER TABLE public.chat_messages DROP CONSTRAINT ' || constraint_name;
        RAISE NOTICE 'Dropped existing constraint: %', constraint_name;
    END IF;

    -- 3. Add the new constraint with 'quotation' included
    ALTER TABLE public.chat_messages 
    ADD CONSTRAINT chat_messages_message_type_check 
    CHECK (message_type IN (
        'text', 
        'image', 
        'file', 
        'system', 
        'orderRequest', 
        'appointmentRequest', 
        'paymentRequest', 
        'quotation', 
        'vendorResponse', 
        'groupCreated', 
        'memberJoined', 
        'memberLeft', 
        'memberRemoved'
    ));
    
    RAISE NOTICE 'Added new constraint: chat_messages_message_type_check';
END $$;
