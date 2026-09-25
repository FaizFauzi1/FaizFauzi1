import http from 'k6/http';
import { check, sleep } from 'k6';
import { Config } from '../config/config.js';
import { TestDataGenerator } from '../helpers/data.js';

/**
 * Scenario: Supabase Storage Performance Flow
 * 1. Download latency of public asset endpoint
 * 2. Upload throughput & latency (controlled & opt-in via ALLOW_STORAGE_UPLOAD_TESTS)
 * 3. File cleanup
 */
export function scenarioStorage(authToken = null) {
  // 1. Download Latency Test (Public bucket read)
  // Requesting a common bucket health / public object check
  const publicUrl = Config.storageUrl('object/public/service-images/placeholder.png');
  const dlRes = http.get(publicUrl, {
    tags: { name: 'storage_download_public' },
  });

  // Response can be 200 or 404 (if placeholder doesn't exist), but should respond within SLA
  check(dlRes, {
    'storage dl status is responded': (r) => r.status === 200 || r.status === 404,
  });

  sleep(0.5);

  // 2. Upload Test (Only if explicitly enabled and authenticated)
  if (Config.allowStorageUploadTests && authToken) {
    const filename = `k6_test_${Date.now()}.png`;
    const vendorId = Config.vendor.id || '00000000-0000-0000-0000-000000000002';
    const uploadUrl = Config.storageUrl(`object/service-images/${vendorId}/${filename}`);

    const imageBase64 = TestDataGenerator.generateDummyImageBytes();

    const uploadRes = http.post(uploadUrl, imageBase64, {
      headers: {
        'apikey': Config.supabaseAnonKey,
        'Authorization': `Bearer ${authToken}`,
        'Content-Type': 'image/png',
      },
      tags: { name: 'storage_upload_synthetic' },
    });

    check(uploadRes, {
      'storage upload accepted or handled': (r) => r.status === 200 || r.status === 201 || r.status === 400,
    });

    sleep(0.5);

    // 3. Cleanup uploaded test object
    if (uploadRes.status === 200 || uploadRes.status === 201) {
      http.del(uploadUrl, null, {
        headers: {
          'apikey': Config.supabaseAnonKey,
          'Authorization': `Bearer ${authToken}`,
        },
        tags: { name: 'storage_delete_synthetic' },
      });
    }
  }

  sleep(1);
}
