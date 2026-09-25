import { Thresholds } from '../config/thresholds.js';
import { generateCustomSummary } from '../helpers/reporter.js';
import { AuthService } from '../helpers/auth.js';
import { Config } from '../config/config.js';
import { scenarioVendorBrowsing } from '../scenarios/vendor-browsing.js';
import { scenarioSearch } from '../scenarios/search.js';
import { scenarioPackages } from '../scenarios/packages.js';
import { scenarioCustomer } from '../scenarios/customer.js';
import { sleep } from 'k6';

const targetGroup = __ENV.TEST_GROUP || 'browsing'; // 'browsing' | 'search' | 'packages' | 'customer'
const vus = parseInt(__ENV.GROUP_VUS || '150', 10);
const duration = __ENV.GROUP_DURATION || '45s';

export const options = {
  vus: vus,
  duration: duration,
  thresholds: {
    http_req_duration: ['p(95)<3000'],
    http_req_failed: ['rate<0.05'],
  },
};

export function setup() {
  console.log(`--- Running EventEase Endpoint Group Test ---`);
  console.log(`Target Group: ${targetGroup.toUpperCase()} | VUs: ${vus} | Duration: ${duration}`);
  let token = null;
  const login = AuthService.login(Config.customer.email, Config.customer.password, 'group_setup_auth');
  if (login.success) token = login.accessToken;
  return { token };
}

export default function (data) {
  switch (targetGroup.toLowerCase()) {
    case 'browsing':
      scenarioVendorBrowsing(data.token);
      break;
    case 'search':
      scenarioSearch();
      break;
    case 'packages':
      scenarioPackages(data.token);
      break;
    case 'customer':
      scenarioCustomer(data.token);
      break;
    default:
      console.error(`Unknown test group: ${targetGroup}. Use browsing, search, packages, or customer.`);
      scenarioVendorBrowsing(data.token);
  }

  sleep(0.5 + Math.random() * 0.5);
}

export function handleSummary(data) {
  return generateCustomSummary(data, `Endpoint Group: ${targetGroup.toUpperCase()}`);
}
