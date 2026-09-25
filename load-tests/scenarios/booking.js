import { SupabaseHttpClient } from '../helpers/client.js';
import { Checks } from '../helpers/checks.js';
import { TestDataGenerator } from '../helpers/data.js';
import { Config } from '../config/config.js';
import { sleep } from 'k6';

const client = new SupabaseHttpClient();

/**
 * Scenario: Booking Flow
 * Tests service booking lifecycle:
 * 1. Submit a booking request
 * 2. Retrieve the newly created booking
 * 3. Update status (e.g. to 'confirmed' or 'cancelled')
 * Note: Only performs insert/update when ALLOW_MUTATIVE_TESTS is enabled,
 * otherwise performs read validation to protect production data.
 */
export function scenarioBooking(authToken = null) {
  if (authToken) client.setAuthToken(authToken);

  // If writes are not permitted, execute safe read validation
  if (!Config.allowMutativeTests) {
    const listRes = client.get(
      'bookings',
      'select=id,booking_date,status,total_amount&limit=10&order=created_at.desc',
      {},
      { name: 'booking_read_safe' }
    );
    Checks.isOk(listRes, 'booking_read_safe');
    sleep(1);
    return;
  }

  const customerId = Config.customer.id || '00000000-0000-0000-0000-000000000001';
  const vendorId = Config.vendor.id || Config.testVendorId || '00000000-0000-0000-0000-000000000002';
  const serviceId = Config.testServiceId || null;

  const payload = TestDataGenerator.bookingPayload(customerId, vendorId, serviceId);

  // 1. Create Booking
  const createRes = client.post(
    'bookings',
    payload,
    {},
    { name: 'booking_create' }
  );

  const isCreated = Checks.isSuccess(createRes, 'booking_create');
  let newBookingId = null;

  if (isCreated) {
    try {
      const records = JSON.parse(createRes.body);
      if (Array.isArray(records) && records.length > 0) {
        newBookingId = records[0].id;
      }
    } catch (_) {}
  }

  sleep(0.5);

  // 2. Status Update
  if (newBookingId) {
    const updateRes = client.patch(
      'bookings',
      `id=eq.${newBookingId}`,
      { status: 'cancelled', updated_at: new Date().toISOString() },
      {},
      { name: 'booking_update_status' }
    );
    Checks.isSuccess(updateRes, 'booking_update_status');

    // 3. Clean up test record if allowable
    client.del('bookings', `id=eq.${newBookingId}`, {}, { name: 'booking_cleanup' });
  }

  sleep(1);
}
