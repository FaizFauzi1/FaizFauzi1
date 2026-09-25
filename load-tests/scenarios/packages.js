import { SupabaseHttpClient } from '../helpers/client.js';
import { Checks } from '../helpers/checks.js';
import { Config } from '../config/config.js';
import { sleep } from 'k6';

const client = new SupabaseHttpClient();

/**
 * Scenario: Vendor Package & Product Management Flow
 * Tests service package hierarchy and nested component retrieval:
 * 1. Fetch vendor services
 * 2. Fetch pricing tiers for service
 * 3. Fetch components with nested items
 */
export function scenarioPackages(authToken = null) {
  if (authToken) client.setAuthToken(authToken);

  const vendorId = Config.vendor.id || Config.testVendorId;
  let serviceId = Config.testServiceId;

  // 1. Vendor Services List:
  // If specific vendor configured, query that vendor; otherwise fetch active services
  // to dynamically discover real IDs and avoid query plan misses on empty sets.
  const serviceQuery = vendorId
    ? `vendor_id=eq.${vendorId}&select=*&limit=10`
    : 'select=*&is_active=eq.true&limit=10';

  const servicesRes = client.get(
    'vendor_services',
    serviceQuery,
    {},
    { name: 'packages_vendor_services' }
  );
  Checks.isOk(servicesRes, 'packages_vendor_services');

  // Dynamically extract real service ID from returned services
  if (!serviceId) {
    try {
      const services = JSON.parse(servicesRes.body);
      if (Array.isArray(services) && services.length > 0 && services[0].id) {
        serviceId = services[0].id;
      }
    } catch (_) {}
  }

  // Safe fallback if database has no active services
  if (!serviceId) {
    serviceId = '00000000-0000-0000-0000-000000000003';
  }

  sleep(0.5);

  // 2. Service Pricing Tiers
  const tiersRes = client.get(
    'service_pricing_tiers',
    `service_id=eq.${serviceId}&select=*`,
    {},
    { name: 'packages_pricing_tiers' }
  );
  Checks.isOk(tiersRes, 'packages_pricing_tiers');

  sleep(0.5);

  // 3. Components with nested items join
  const componentsRes = client.get(
    'service_components',
    `service_id=eq.${serviceId}&select=*,service_items(*)`,
    {},
    { name: 'packages_components_and_items' }
  );
  Checks.isOk(componentsRes, 'packages_components_and_items');

  sleep(1);
}

