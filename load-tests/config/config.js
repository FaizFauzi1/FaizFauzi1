/**
 * EventEase Load Testing Configuration
 * Reads configuration from k6 execution environment (__ENV) with safe defaults.
 */

export const Config = {
  // Supabase Base URLs
  supabaseUrl: (__ENV.SUPABASE_URL || 'https://lqvsavyfbnarwsunbfzm.supabase.co').replace(/\/+$/, ''),
  supabaseAnonKey: __ENV.SUPABASE_ANON_KEY || 'sb_publishable_tAUtEvgarcJEtlo50Bdtxg_m9SVzy_5',

  // Authentication Test Accounts (empty if not explicitly configured)
  customer: {
    email: __ENV.TEST_CUSTOMER_EMAIL || '',
    password: __ENV.TEST_CUSTOMER_PASSWORD || '',
    id: __ENV.TEST_CUSTOMER_ID || '',
  },
  vendor: {
    email: __ENV.TEST_VENDOR_EMAIL || '',
    password: __ENV.TEST_VENDOR_PASSWORD || '',
    id: __ENV.TEST_VENDOR_ID || '',
  },
  organizer: {
    email: __ENV.TEST_ORGANIZER_EMAIL || '',
    password: __ENV.TEST_ORGANIZER_PASSWORD || '',
  },
  admin: {
    email: __ENV.TEST_ADMIN_EMAIL || '',
    password: __ENV.TEST_ADMIN_PASSWORD || '',
  },

  hasCustomerAuth() {
    return Boolean(this.customer.email && this.customer.password);
  },

  hasVendorAuth() {
    return Boolean(this.vendor.email && this.vendor.password);
  },

  // Test Target IDs (Fallback to blank/dynamic if not set)
  testServiceId: __ENV.TEST_SERVICE_ID || '',
  testPackageId: __ENV.TEST_PACKAGE_ID || '',
  testVendorId: __ENV.TEST_VENDOR_ID || '',
  testCustomerId: __ENV.TEST_CUSTOMER_ID || '',
  testEventId: __ENV.TEST_EVENT_ID || '',
  testExpoId: __ENV.TEST_EXPO_ID || '',
  testConversationId: __ENV.TEST_CONVERSATION_ID || '',

  // Safety Controls
  allowMutativeTests: (__ENV.ALLOW_MUTATIVE_TESTS === 'true'),
  allowPaymentSandboxTests: (__ENV.ALLOW_PAYMENT_SANDBOX_TESTS === 'true'),
  allowStorageUploadTests: (__ENV.ALLOW_STORAGE_UPLOAD_TESTS === 'true'),
  allowRealtimeStressTests: (__ENV.ALLOW_REALTIME_STRESS_TESTS === 'true'),

  // Execution Limits
  maxVUsStress: parseInt(__ENV.MAX_VUS_STRESS || '500', 10),
  soakDuration: __ENV.SOAK_DURATION || '30m',
  concurrencyVUs: parseInt(__ENV.BOOKING_CONCURRENCY_VUS || '50', 10),
  requestTimeout: __ENV.HTTP_TIMEOUT || '30s',

  // Webhook Tokens
  xenditWebhookToken: __ENV.XENDIT_WEBHOOK_VERIFICATION_TOKEN || 'YOUR_XENDIT_WEBHOOK_VERIFICATION_TOKEN',

  // URL Helper Constructors
  restUrl(path, query = '') {
    const cleanPath = path.startsWith('/') ? path.substring(1) : path;
    const queryString = query ? (query.startsWith('?') ? query : `?${query}`) : '';
    return `${this.supabaseUrl}/rest/v1/${cleanPath}${queryString}`;
  },

  authUrl(endpoint) {
    const cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return `${this.supabaseUrl}/auth/v1/${cleanEndpoint}`;
  },

  storageUrl(endpoint) {
    const cleanEndpoint = endpoint.startsWith('/') ? endpoint.substring(1) : endpoint;
    return `${this.supabaseUrl}/storage/v1/${cleanEndpoint}`;
  },

  functionsUrl(functionName) {
    const cleanName = functionName.startsWith('/') ? functionName.substring(1) : functionName;
    return `${this.supabaseUrl}/functions/v1/${cleanName}`;
  },

  realtimeWsUrl() {
    const wsBase = this.supabaseUrl.replace(/^http/, 'ws');
    return `${wsBase}/realtime/v1/websocket?apikey=${this.supabaseAnonKey}&vsn=1.0.0`;
  }
};
