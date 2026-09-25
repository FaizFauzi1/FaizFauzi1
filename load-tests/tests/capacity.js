import { generateCustomSummary } from '../helpers/reporter.js';
import { AuthService } from '../helpers/auth.js';
import { Config } from '../config/config.js';
import { scenarioVendorBrowsing } from '../scenarios/vendor-browsing.js';
import { scenarioSearch } from '../scenarios/search.js';
import { scenarioPackages } from '../scenarios/packages.js';
import { scenarioCustomer } from '../scenarios/customer.js';
import { sleep } from 'k6';

const stageDuration = __ENV.STAGE_DURATION || '1m';

/**
 * Targeted Stepped Capacity Test: 200 -> 300 -> 400 -> 500 -> 600 -> 700 VUs
 * Designed to pinpoint the exact VU level and throughput where connection pool queueing begins.
 */
export const options = {
  stages: [
    { duration: '30s', target: 200 },
    { duration: stageDuration, target: 200 },
    { duration: '20s', target: 300 },
    { duration: stageDuration, target: 300 },
    { duration: '20s', target: 400 },
    { duration: stageDuration, target: 400 },
    { duration: '20s', target: 500 },
    { duration: stageDuration, target: 500 },
    { duration: '20s', target: 600 },
    { duration: stageDuration, target: 600 },
    { duration: '20s', target: 700 },
    { duration: stageDuration, target: 700 },
    { duration: '30s', target: 0 },
  ],
  thresholds: {
    http_req_failed: ['rate<0.10'], // Allow up to 10% to capture full degradation curve
  },
};

export function setup() {
  console.log('--- Starting EventEase Stepped Capacity Test (200 -> 700 VUs) ---');
  let token = null;
  const login = AuthService.login(Config.customer.email, Config.customer.password, 'capacity_setup_auth');
  if (login.success) token = login.accessToken;
  return { token };
}

export default function (data) {
  const rand = Math.random();

  if (rand < 0.5) {
    scenarioVendorBrowsing(data.token);
  } else if (rand < 0.8) {
    scenarioSearch();
  } else if (rand < 0.9) {
    scenarioPackages(data.token);
  } else {
    scenarioCustomer(data.token);
  }

  sleep(0.5 + Math.random());
}

export function handleSummary(data) {
  return generateCustomSummary(data, 'Stepped Capacity Test (200-700 VUs)');
}
