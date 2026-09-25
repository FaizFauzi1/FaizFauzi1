import { SupabaseHttpClient } from '../helpers/client.js';
import { Checks } from '../helpers/checks.js';
import { TestDataGenerator } from '../helpers/data.js';
import { Config } from '../config/config.js';
import { sleep } from 'k6';

const client = new SupabaseHttpClient();

/**
 * Scenario: Review Flow
 * 1. Fetch reviews for a specific service
 * 2. Fetch all reviews for a vendor (with inner join on vendor_services)
 * 3. Submit a review (guarded by mutative flag)
 */
export function scenarioReview(authToken = null) {
  if (authToken) client.setAuthToken(authToken);

  const targetServiceId = Config.testServiceId || '00000000-0000-0000-0000-000000000003';
  const targetVendorId = Config.testVendorId || '00000000-0000-0000-0000-000000000002';

  // 1. Fetch reviews by service
  const serviceReviewRes = client.get(
    'service_reviews',
    `service_id=eq.${targetServiceId}&select=*&order=created_at.desc&limit=20`,
    {},
    { name: 'reviews_by_service' }
  );
  Checks.isOk(serviceReviewRes, 'reviews_by_service');

  sleep(0.5);

  // 2. Fetch reviews by vendor (Joined Query)
  const vendorReviewRes = client.get(
    'service_reviews',
    `select=*,vendor_services!inner(vendor_id)&vendor_services.vendor_id=eq.${targetVendorId}&order=created_at.desc&limit=20`,
    {},
    { name: 'reviews_by_vendor_join' }
  );
  Checks.isOk(vendorReviewRes, 'reviews_by_vendor_join');

  // 3. Post a review (guarded)
  if (Config.allowMutativeTests) {
    const customerId = Config.customer.id || '00000000-0000-0000-0000-000000000001';
    const payload = TestDataGenerator.reviewPayload(customerId, targetServiceId);
    const postRes = client.post(
      'service_reviews',
      payload,
      {},
      { name: 'reviews_post' }
    );
    Checks.isSuccess(postRes, 'reviews_post');
  }

  sleep(1);
}
