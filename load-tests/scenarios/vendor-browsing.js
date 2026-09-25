import { SupabaseHttpClient } from '../helpers/client.js';
import { Checks } from '../helpers/checks.js';
import { Config } from '../config/config.js';
import { sleep } from 'k6';

const client = new SupabaseHttpClient();

/**
 * Scenario: Vendor Browsing Flow
 * Simulates customers browsing the EventEase marketplace:
 * 1. Fetch active service categories
 * 2. Fetch event types
 * 3. Fetch top-priority vendors
 * 4. Fetch featured venues
 * 5. Open vendor profile with joined owners & banking details
 * 6. Open vendor service packages
 */
export function scenarioVendorBrowsing(authToken = null) {
  if (authToken) client.setAuthToken(authToken);

  // 1. Fetch active service categories (targeted columns aligned with category_provider.dart)
  const categoriesRes = client.get(
    'service_categories',
    'select=id,name,slug,icon_name,display_order&is_active=eq.true&order=display_order.asc',
    {},
    { name: 'browse_categories' }
  );
  Checks.isOk(categoriesRes, 'browse_categories');

  // 2. Fetch event types
  const eventTypesRes = client.get(
    'event_types',
    'select=*&order=name.asc',
    {},
    { name: 'browse_event_types' }
  );
  Checks.isOk(eventTypesRes, 'browse_event_types');

  sleep(0.5);

  // 3. Top priority vendors
  const vendorsRes = client.get(
    'vendor_profiles',
    'select=*&order=priority_score.desc&limit=20',
    {},
    { name: 'browse_vendors_list' }
  );
  Checks.isOk(vendorsRes, 'browse_vendors_list');
  Checks.isJsonArray(vendorsRes, 0, 'vendors_array');

  // Extract a vendor ID to inspect details
  let targetVendorId = Config.testVendorId;
  try {
    const vendors = JSON.parse(vendorsRes.body);
    if (Array.isArray(vendors) && vendors.length > 0) {
      if (!targetVendorId || targetVendorId.startsWith('00000000-0000')) {
        targetVendorId = vendors[0].id;
      }
    }
  } catch (_) {}

  // 4. Featured Venues
  const venuesRes = client.get(
    'vendor_services',
    'select=*&category=eq.venue&is_active=eq.true&limit=10',
    {},
    { name: 'browse_venues_list' }
  );
  Checks.isOk(venuesRes, 'browse_venues_list');

  sleep(1);

  // 5. Vendor Details (Profile + Joins)
  if (targetVendorId) {
    const detailRes = client.get(
      'vendor_profiles',
      `select=*,vendor_owners(*),vendor_banking(*)&id=eq.${targetVendorId}`,
      {},
      { name: 'browse_vendor_details' }
    );
    Checks.isOk(detailRes, 'browse_vendor_details');

    // 6. Vendor Services/Packages
    const servicesRes = client.get(
      'vendor_services',
      `select=*&vendor_id=eq.${targetVendorId}&is_active=eq.true`,
      {},
      { name: 'browse_vendor_services' }
    );
    Checks.isOk(servicesRes, 'browse_vendor_services');
  }

  sleep(1);
}
