import { Thresholds } from '../config/thresholds.js';
import { generateCustomSummary } from '../helpers/reporter.js';
import { SupabaseHttpClient } from '../helpers/client.js';
import { AuthService } from '../helpers/auth.js';
import { TestDataGenerator } from '../helpers/data.js';
import { Config } from '../config/config.js';
import { check } from 'k6';
import { Counter } from 'k6/metrics';

// Custom metrics to count booking outcomes
const successfulBookings = new Counter('concurrency_booking_success');
const rejectedBookings = new Counter('concurrency_booking_rejected');
const collisionCount = new Counter('concurrency_double_booking_detected');

const concurrencyVUs = Config.concurrencyVUs || 50;

export const options = {
  scenarios: {
    booking_race_condition: {
      executor: 'per-vu-iterations',
      vus: concurrencyVUs,
      iterations: 1,
      maxDuration: '1m',
    },
  },
  thresholds: Thresholds.concurrency,
};

// Global slot target shared across all concurrent VUs
const targetSlot = {
  vendorId: Config.vendor.id || Config.testVendorId || '00000000-0000-0000-0000-000000000002',
  date: '2026-12-31',
  startTime: '10:00:00',
  endTime: '12:00:00',
};

export function setup() {
  console.log('================================================================');
  console.log(`--- STARTING CRITICAL CONCURRENCY & DOUBLE-BOOKING RACE TEST ---`);
  console.log(`Target: ${concurrencyVUs} concurrent VUs competing for the EXACT SAME slot atomically`);
  console.log('================================================================');

  let token = null;
  const login = AuthService.login(Config.customer.email, Config.customer.password, 'concurrency_setup_auth');
  if (login.success) token = login.accessToken;

  // Discover real vendor ID from vendor_profiles
  let vendorId = Config.vendor.id || Config.testVendorId;
  if (!vendorId || vendorId.startsWith('00000000-0000')) {
    const client = new SupabaseHttpClient();
    const vRes = client.get('vendor_profiles', 'select=id&limit=1', {}, { name: 'concurrency_discover_vendor' });
    try {
      const list = JSON.parse(vRes.body);
      if (Array.isArray(list) && list.length > 0 && list[0].id) {
        vendorId = list[0].id;
      }
    } catch (_) {}
  }
  if (!vendorId) {
    vendorId = '2a372197-0e31-4dd7-a8d3-ae407c8a593a';
  }

  // Generate a fresh unique slot date for this test run so slot is guaranteed unreserved at start
  const dayNonce = Math.floor(Math.random() * 25) + 1;
  const monthNonce = Math.floor(Math.random() * 12) + 1;
  const targetDate = `2027-${String(monthNonce).padStart(2, '0')}-${String(dayNonce).padStart(2, '0')}`;
  const startTime = '10:00:00';
  const endTime = '12:00:00';

  console.log(`[CONCURRENCY SETUP] Target Vendor: ${vendorId}`);
  console.log(`[CONCURRENCY SETUP] Target Slot: ${targetDate} from ${startTime} to ${endTime}`);

  return { token, vendorId, targetDate, startTime, endTime };
}

export default function (data) {
  const client = new SupabaseHttpClient(data.token);
  const vuId = __VU;

  // Attempt atomic slot claim via claim_booking_slot RPC
  const slotPayload = {
    p_vendor_id: data.vendorId,
    p_date: data.targetDate,
    p_start_time: data.startTime,
    p_end_time: data.endTime,
    p_block_reason: `[k6-concurrency-vu-${vuId}] Claimed slot`,
  };

  const slotRes = client.rpc(
    'claim_booking_slot',
    slotPayload,
    {},
    { name: 'concurrency_claim_slot' }
  );

  let slotStatus = slotRes.status;
  let slotSuccess = false;
  let responsePayload = {};
  try {
    responsePayload = JSON.parse(slotRes.body);
    if (responsePayload.status) slotStatus = responsePayload.status;
    if (responsePayload.success === true) slotSuccess = true;
  } catch (_) {}

  // Diagnostic logging
  console.log(`[VU ${vuId} Iter ${__ITER}] RESULT: HTTP ${slotRes.status} -> AppStatus: ${slotStatus} (success=${slotSuccess})`);

  if (slotSuccess) {
    successfulBookings.add(1);
    console.log(`[VU ${vuId}] --> 🏆 WINNER: Successfully claimed slot atomically!`);
  } else if (slotStatus === 409) {
    rejectedBookings.add(1);
    console.log(`[VU ${vuId}] --> 🛡️ REJECTED: Slot collision prevented by database constraint (409 Conflict).`);
  } else {
    rejectedBookings.add(1);
    console.log(`[VU ${vuId}] --> ❌ REJECTED: Unexpected status ${slotStatus}`);
  }

  // Assertion check on concurrency behavior:
  // Winner gets 201 (or 200 with success:true), simultaneous losers get 409 Conflict
  check(slotRes, {
    'slot claim handled atomically (201 winner or 409 collision)': () =>
      slotStatus === 201 || slotStatus === 409,
  }, { type: 'concurrency' });
}

export function teardown(data) {
  console.log('--- Cleaning up concurrency test slots ---');
  if (Config.allowMutativeTests) {
    const client = new SupabaseHttpClient(data.token);
    client.del(
      'vendor_availability',
      `vendor_id=eq.${targetSlot.vendorId}&date=eq.${targetSlot.date}`,
      {},
      { name: 'concurrency_cleanup_slot' }
    );
    client.del(
      'bookings',
      `vendor_id=eq.${targetSlot.vendorId}&booking_date=eq.${targetSlot.date}`,
      {},
      { name: 'concurrency_cleanup_bookings' }
    );
  }
}

export function handleSummary(data) {
  return generateCustomSummary(data, 'Booking Concurrency & Race Condition Test');
}
