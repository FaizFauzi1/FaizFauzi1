import { SupabaseHttpClient } from '../helpers/client.js';
import { Checks } from '../helpers/checks.js';
import { Config } from '../config/config.js';
import { sleep } from 'k6';

const client = new SupabaseHttpClient();

/**
 * Scenario: Customer Operations Flow
 * Validates customer-specific data queries under load:
 * 1. Customer user profile lookup
 * 2. Customer bookings with joined vendors, services, and installments
 * 3. Customer shop orders with order items
 * 4. Customer appointments calendar
 */
export function scenarioCustomer(authToken = null, customerId = null) {
  if (authToken) client.setAuthToken(authToken);
  const targetId = customerId || Config.customer.id || '00000000-0000-0000-0000-000000000001';

  // 1. Customer User Profile
  const profileRes = client.get(
    'customer_user',
    `id=eq.${targetId}&select=*`,
    {},
    { name: 'customer_profile' }
  );
  Checks.isOk(profileRes, 'customer_profile');

  sleep(0.5);

  // 2. Customer Bookings with Nested Relations
  const bookingsRes = client.get(
    'bookings',
    `customer_id=eq.${targetId}&select=*,customer_user(*),vendor_profiles(business_name),vendor_services(name),installment_plans(*,installment_payments(*))&order=booking_date.desc`,
    {},
    { name: 'customer_bookings_deep' }
  );
  Checks.isOk(bookingsRes, 'customer_bookings_deep');

  sleep(0.5);

  // 3. Customer Shop Orders
  const ordersRes = client.get(
    'shop_orders',
    `customer_id=eq.${targetId}&select=*,items:shop_order_items(*)&order=order_date.desc`,
    {},
    { name: 'customer_shop_orders' }
  );
  Checks.isOk(ordersRes, 'customer_shop_orders');

  sleep(0.5);

  // 4. Customer Appointments
  const apptRes = client.get(
    'appointments',
    `customer_id=eq.${targetId}&select=*&order=scheduled_date.desc`,
    {},
    { name: 'customer_appointments' }
  );
  Checks.isOk(apptRes, 'customer_appointments');

  sleep(1);
}
