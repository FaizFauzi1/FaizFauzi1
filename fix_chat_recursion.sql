-- ===========================================
-- FIX: Infinite Recursion in Chat RLS
-- ===========================================

-- 1. Create a security definer function to check membership
-- This bypasses RLS within the function itself, breaking infinite recursion
CREATE OR REPLACE FUNCTION public.check_chat_membership(conv_id UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.chat_group_members
    WHERE conversation_id = conv_id
    AND user_id = auth.uid()
    AND is_active = true
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER SET search_path = public;

-- 2. Clean up existing chat policies
DROP POLICY IF EXISTS "Users can view conversations they are part of" ON chat_conversations;
DROP POLICY IF EXISTS "Users can view members of their conversations" ON chat_group_members;
DROP POLICY IF EXISTS "Users can view messages in their conversations" ON chat_messages;
DROP POLICY IF EXISTS "Users can send messages to their conversations" ON chat_messages;

-- 3. Re-create policies using the helper function

-- Policy for chat_conversations
CREATE POLICY "Users can view conversations they are part of" ON chat_conversations
    FOR SELECT USING (check_chat_membership(id));

CREATE POLICY "Users can create conversations" ON chat_conversations
    FOR INSERT WITH CHECK (auth.uid() = created_by);

-- Policy for chat_group_members (THIS IS WHERE THE RECURSION WAS)
-- A user can see a membership record if they themselves are a member of that conversation
CREATE POLICY "Users can view members of their conversations" ON chat_group_members
    FOR SELECT USING (check_chat_membership(conversation_id));

CREATE POLICY "Users can add members to their own conversations" ON chat_group_members
    FOR INSERT WITH CHECK (
        EXISTS (
            SELECT 1 FROM chat_conversations
            WHERE id = conversation_id
            AND created_by = auth.uid()
        )
    );

-- Policy for chat_messages (Select)
CREATE POLICY "Users can view messages in their conversations" ON chat_messages
    FOR SELECT USING (check_chat_membership(conversation_id));

-- Policy for chat_messages (Insert)
CREATE POLICY "Users can send messages to their conversations" ON chat_messages
    FOR INSERT WITH CHECK (check_chat_membership(conversation_id));

-- 4. Enable RLS (just in case)
ALTER TABLE chat_conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_group_members ENABLE ROW LEVEL SECURITY;
ALTER TABLE chat_messages ENABLE ROW LEVEL SECURITY;
