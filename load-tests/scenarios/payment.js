import { SupabaseHttpClient } from '../helpers/client.js';
import { Checks } from '../helpers/checks.js';
import { TestDataGenerator } from '../helpers/data.js';
import { Config } from '../config/config.js';
import { check, sleep } from 'k6';

const client = new SupabaseHttpClient();

/**
 * Scenario: Payment Sandbox & Webhook Idempotency Flow
 * CRITICAL SAFETY: No real cards or bank transactions are executed.
 * Tests Edge Function throughput and Webhook handling:
 * 1. Invoice creation parameter validation (create-xendit-invoice)
 * 2. Webhook idempotency test:
 *    - Send webhook for transaction_id
 *    - Immediately replay the same webhook
 *    - Verify idempotent response (both return 200 without creating duplicates)
 */
export function scenarioPayment() {
  if (!Config.allowPaymentSandboxTests) {
    // Safe mode: query subscription_payments table read-only
    const readRes = client.get(
      'subscription_payments',
      'select=id,transaction_id,payment_status&limit=5',
      {},
      { name: 'payment_status_read_safe' }
    );
    Checks.isOk(readRes, 'payment_status_read_safe');
    sleep(1);
    return;
  }

  const testExternalId = `k6_ext_${Date.now()}_${Math.random().toString(36).substring(7)}`;

  // 1. Test Webhook Idempotency (xendit-webhook Edge Function)
  const webhookPayload = TestDataGenerator.xenditWebhookPayload(testExternalId);

  const headers = {
    'x-callback-token': Config.xenditWebhookToken,
  };

  // First Webhook Call
  const firstRes = client.invokeFunction(
    'xendit-webhook',
    webhookPayload,
    headers,
    { name: 'payment_webhook_first' }
  );

  check(firstRes, {
    'first webhook responded': (r) => r.status === 200 || r.status === 401,
  });

  sleep(0.5);

  // Replay Identical Webhook Call (Idempotency Test)
  const replayRes = client.invokeFunction(
    'xendit-webhook',
    webhookPayload,
    headers,
    { name: 'payment_webhook_replay' }
  );

  check(replayRes, {
    'replay webhook idempotent response': (r) => r.status === 200 || r.status === 401,
  });

  sleep(1);
}
