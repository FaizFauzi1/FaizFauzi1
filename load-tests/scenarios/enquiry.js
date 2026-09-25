import { SupabaseHttpClient } from '../helpers/client.js';
import { Checks } from '../helpers/checks.js';
import { TestDataGenerator } from '../helpers/data.js';
import { Config } from '../config/config.js';
import { sleep } from 'k6';

const client = new SupabaseHttpClient();

/**
 * Scenario: Enquiry & Messaging Flow
 * Tests chat queries and message dispatch under load:
 * 1. Fetch conversations with joined members & recent messages
 * 2. Fetch specific conversation message thread (paged 50)
 * 3. Send message payload (if mutative tests enabled)
 */
export function scenarioEnquiry(authToken = null) {
  if (authToken) client.setAuthToken(authToken);

  // 1. Fetch active conversations
  const convRes = client.get(
    'chat_conversations',
    'select=*,members:chat_group_members(*),messages:chat_messages(*)&is_active=eq.true&order=updated_at.desc&limit=10',
    {},
    { name: 'chat_conversations_list' }
  );
  Checks.isOk(convRes, 'chat_conversations_list');

  let targetConvId = Config.testConversationId;
  try {
    const list = JSON.parse(convRes.body);
    if (list.length > 0 && !targetConvId) {
      targetConvId = list[0].id;
    }
  } catch (_) {}

  sleep(0.5);

  // 2. Fetch message history for a conversation
  if (targetConvId) {
    const msgRes = client.get(
      'chat_messages',
      `conversation_id=eq.${targetConvId}&select=*&order=created_at.desc&limit=50`,
      {},
      { name: 'chat_messages_history' }
    );
    Checks.isOk(msgRes, 'chat_messages_history');

    // 3. Post a message (if allowed)
    if (Config.allowMutativeTests) {
      const senderId = Config.customer.id || '00000000-0000-0000-0000-000000000001';
      const payload = TestDataGenerator.chatMessagePayload(targetConvId, senderId);
      const postRes = client.post(
        'chat_messages',
        payload,
        {},
        { name: 'chat_send_message' }
      );
      Checks.isSuccess(postRes, 'chat_send_message');
    }
  }

  sleep(1);
}
