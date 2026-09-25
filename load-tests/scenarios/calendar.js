import { SupabaseHttpClient } from '../helpers/client.js';
import { Checks } from '../helpers/checks.js';
import { Config } from '../config/config.js';
import { sleep } from 'k6';

const client = new SupabaseHttpClient();

/**
 * Scenario: Calendar & Vendor Availability Flow
 * 1. Fetch vendor availability rules & blocked slots
 * 2. Fetch upcoming vendor appointments
 */
export function scenarioCalendar(authToken = null) {
  if (authToken) client.setAuthToken(authToken);

  const vendorId = Config.vendor.id || Config.testVendorId || '00000000-0000-0000-0000-000000000002';

  // 1. Vendor Availability
  const availRes = client.get(
    'vendor_availability',
    `vendor_id=eq.${vendorId}&select=*&order=date.asc&limit=30`,
    {},
    { name: 'calendar_vendor_availability' }
  );
  Checks.isOk(availRes, 'calendar_vendor_availability');

  sleep(0.5);

  // 2. Scheduled Appointments
  const apptRes = client.get(
    'appointments',
    `vendor_id=eq.${vendorId}&select=*&order=scheduled_date.asc&limit=30`,
    {},
    { name: 'calendar_vendor_appointments' }
  );
  Checks.isOk(apptRes, 'calendar_vendor_appointments');

  sleep(1);
}
