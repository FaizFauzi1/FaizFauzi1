import { SupabaseHttpClient } from '../helpers/client.js';
import { Checks } from '../helpers/checks.js';
import { Config } from '../config/config.js';
import { sleep } from 'k6';

const client = new SupabaseHttpClient();

/**
 * Scenario: Vendor Operations Flow
 * Validates vendor dashboard, analytics RPC, and management queries:
 * 1. Vendor profile data
 * 2. Vendor incoming bookings
 * 3. Vendor shop orders (with inner join filter)
 * 4. Vendor aggregated analytics RPC (get_vendor_analytics_aggregated)
 * 5. Vendor order settings
 */
export function scenarioVendor(authToken = null, vendorId = null) {
  if (authToken) client.setAuthToken(authToken);
  let targetId = vendorId || Config.vendor.id || Config.testVendorId;

  // If no target ID provided or it's a dummy UUID, fetch a real vendor profile ID
  if (!targetId || targetId.startsWith('00000000-0000')) {
    const listRes = client.get('vendor_profiles', 'select=id&limit=1', {}, { name: 'vendor_discover_id' });
    try {
      const list = JSON.parse(listRes.body);
      if (Array.isArray(list) && list.length > 0 && list[0].id) {
        targetId = list[0].id;
      }
    } catch (_) {}
  }
  if (!targetId) {
    targetId = '00000000-0000-0000-0000-000000000002';
  }

  // 1. Vendor Profile
  const profileRes = client.get(
    'vendor_profiles',
    `id=eq.${targetId}&select=*`,
    {},
    { name: 'vendor_profile' }
  );
  Checks.isOk(profileRes, 'vendor_profile');

  sleep(0.5);

  // 2. Vendor Bookings
  const bookingsRes = client.get(
    'bookings',
    `vendor_id=eq.${targetId}&select=*,customer_user(*),vendor_services(name)&order=booking_date.desc&limit=25`,
    {},
    { name: 'vendor_bookings' }
  );
  Checks.isOk(bookingsRes, 'vendor_bookings');

  sleep(0.5);

  // 3. Vendor Shop Orders
  const ordersRes = client.get(
    'shop_orders',
    `select=*,items:shop_order_items!inner(*)&items.vendor_id=eq.${targetId}&order=order_date.desc&limit=25`,
    {},
    { name: 'vendor_shop_orders' }
  );
  Checks.isOk(ordersRes, 'vendor_shop_orders');

  sleep(0.5);

  // 4. Vendor Analytics RPC
  const analyticsRes = client.rpc(
    'get_vendor_analytics_aggregated',
    { vendor_id: targetId },
    {},
    { name: 'vendor_analytics_rpc' }
  );
  // May return 200 or 404 if RPC not installed, verify status handles gracefully
  Checks.isSuccess(analyticsRes, 'vendor_analytics_rpc');

  sleep(0.5);

  // 5. Vendor Order Settings
  const settingsRes = client.get(
    'vendor_order_settings',
    `vendor_id=eq.${targetId}&select=*`,
    {},
    { name: 'vendor_order_settings' }
  );
  Checks.isOk(settingsRes, 'vendor_order_settings');

  sleep(1);
}
