import { Thresholds } from '../config/thresholds.js';
import { generateCustomSummary } from '../helpers/reporter.js';
import { AuthService } from '../helpers/auth.js';
import { Config } from '../config/config.js';
import { scenarioVendorBrowsing } from '../scenarios/vendor-browsing.js';
import { scenarioSearch } from '../scenarios/search.js';
import { scenarioPackages } from '../scenarios/packages.js';
import { scenarioCustomer } from '../scenarios/customer.js';
import { sleep } from 'k6';

export const options = {
  vus: 2,
  duration: '30s',
  thresholds: Thresholds.smoke,
};

export function setup() {
  console.log('--- Starting EventEase Smoke Test ---');
  console.log(`Target Supabase URL: ${Config.supabaseUrl}`);
  // Perform a test authentication if test customer credentials are provided
  let token = null;
  const login = AuthService.login(Config.customer.email, Config.customer.password, 'smoke_setup_auth');
  if (login.success) {
    token = login.accessToken;
    console.log('Customer test login: SUCCESS');
  } else {
    console.log('Customer test login skipped/unsuccessful; proceeding with public access mode.');
  }
  return { token };
}

export default function (data) {
  // 1. Vendor Marketplace Browsing
  scenarioVendorBrowsing(data.token);
  sleep(1);

  // 2. Search & Categories
  scenarioSearch();
  sleep(1);

  // 3. Package & Service Details
  scenarioPackages(data.token);
  sleep(1);

  // 4. Basic Customer Queries
  scenarioCustomer(data.token);
  sleep(1);
}

export function handleSummary(data) {
  return generateCustomSummary(data, 'Smoke Test');
}
