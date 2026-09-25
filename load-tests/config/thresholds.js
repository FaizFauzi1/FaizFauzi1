/**
 * EventEase Performance SLA Thresholds
 * Configurable thresholds based on operation characteristics:
 * - Reads: Fast (p95 < 1000ms)
 * - Writes & RPCs: Tolerates slightly higher latency (p95 < 1500ms)
 * - Error rate: Strict (< 1% for standard tests)
 */

export const Thresholds = {
  smoke: {
    http_req_failed: ['rate<0.01'],         // < 1% error rate
    http_req_duration: ['p(95)<1000'],      // 95% of requests under 1s
  },

  load: {
    http_req_failed: ['rate<0.01'],         // < 1% error rate
    http_req_duration: [
      'p(50)<400',                          // 50% under 400ms
      'p(90)<800',                          // 90% under 800ms
      'p(95)<1200',                         // 95% under 1.2s
      'p(99)<2500',                         // 99% under 2.5s
    ],
  },

  stress: {
    http_req_failed: ['rate<0.05'],         // < 5% error rate under extreme stress
    http_req_duration: ['p(95)<3000'],      // 95% under 3s before bottleneck collapse
  },

  spike: {
    http_req_failed: ['rate<0.05'],         // < 5% error rate during sudden surge
    http_req_duration: ['p(95)<4000'],      // 95% under 4s during recovery
  },

  soak: {
    http_req_failed: ['rate<0.01'],         // < 1% error rate over sustained duration
    http_req_duration: [
      'p(95)<1500',                         // Memory/connection degradation guard
      'p(99)<3000',
    ],
  },

  concurrency: {
    http_req_failed: ['rate<0.05'],
    'checks{type:concurrency}': ['rate>0.99'], // Correctness check must be near 100%
  }
};
