/**
 * Custom k6 Report Summary Handler
 * Generates structured JSON, console summaries, and HTML dashboard.
 */

export function generateCustomSummary(data, testName = 'EventEase Load Test') {
  const metrics = data.metrics || {};
  const httpDuration = metrics['http_req_duration'] ? metrics['http_req_duration'].values : {};
  const httpReqs = metrics['http_reqs'] ? metrics['http_reqs'].values : {};
  const httpFailed = metrics['http_req_failed'] ? metrics['http_req_failed'].values : {};
  const vus = metrics['vus_max'] ? metrics['vus_max'].values.value : (metrics['vus'] ? metrics['vus'].values.value : 0);

  const totalRequests = httpReqs.count || 0;
  const reqsPerSec = (httpReqs.rate || 0).toFixed(2);
  const failureRate = ((httpFailed.rate || 0) * 100).toFixed(2);

  const failedRequestsCount = httpFailed.passes || 0;

  // Failure classification counters from client.js
  const timeouts = metrics['http_timeouts_count'] ? (metrics['http_timeouts_count'].values.count || 0) : 0;
  const gatewayErrors = metrics['http_gateway_errors_count'] ? (metrics['http_gateway_errors_count'].values.count || 0) : 0;
  const serverErrors = metrics['http_server_errors_count'] ? (metrics['http_server_errors_count'].values.count || 0) : 0;
  const clientErrors = metrics['http_client_errors_count'] ? (metrics['http_client_errors_count'].values.count || 0) : 0;

  // Exact Latency Calculations with fallback to 'med' for p50
  const p50 = (httpDuration['p(50)'] !== undefined ? httpDuration['p(50)'] : (httpDuration['med'] !== undefined ? httpDuration['med'] : 0)).toFixed(2);
  const p90 = (httpDuration['p(90)'] !== undefined ? httpDuration['p(90)'] : 0).toFixed(2);
  const p95 = (httpDuration['p(95)'] !== undefined ? httpDuration['p(95)'] : 0).toFixed(2);
  const p99 = (httpDuration['p(99)'] !== undefined ? httpDuration['p(99)'] : (httpDuration['p(95)'] !== undefined ? httpDuration['p(95)'] : 0)).toFixed(2);
  const avg = (httpDuration.avg !== undefined ? httpDuration.avg : 0).toFixed(2);
  const max = (httpDuration.max !== undefined ? httpDuration.max : 0).toFixed(2);

  const checks = metrics['checks'] ? metrics['checks'].values : {};
  const checksPassed = checks.passes || 0;
  const checksFailed = checks.fails || 0;
  const checksTotal = checksPassed + checksFailed;
  const checksPassRate = checksTotal > 0 ? ((checksPassed / checksTotal) * 100).toFixed(1) : '100.0';

  // Recursive check extraction
  function collectChecks(group) {
    let list = [];
    if (group.checks && group.checks.length > 0) {
      list = list.concat(group.checks);
    }
    if (group.groups && group.groups.length > 0) {
      for (const g of group.groups) {
        list = list.concat(collectChecks(g));
      }
    }
    return list;
  }

  const allChecks = data.root_group ? collectChecks(data.root_group) : [];
  let checksBreakdown = '\n--- CHECK FAILURE SUMMARY ---\n';
  let failedChecksCount = 0;
  if (allChecks.length > 0) {
    for (const c of allChecks) {
      const fails = c.fails || 0;
      const passes = c.passes || 0;
      if (fails > 0) {
        failedChecksCount++;
        checksBreakdown += `❌ [FAIL] ${c.name}: ${fails} failures (${passes} passed)\n`;
      } else {
        checksBreakdown += `✅ [PASS] ${c.name}: 0 failures (${passes} passed)\n`;
      }
    }
  }

  let failureBreakdown = '';
  if (failedRequestsCount > 0 || timeouts > 0 || gatewayErrors > 0) {
    failureBreakdown = `
--- FAILURE CLASSIFICATION ---
Timeouts (status=0):        ${timeouts} (Connection pool queue starvation / client timeout)
Gateway Errors (502-504):   ${gatewayErrors} (Cloudflare/Supabase upstream capacity limit)
Server Errors (500-599):    ${serverErrors} (Database/API internal errors)
Client Errors (400-499):    ${clientErrors} (Bad request / auth / validation)
`;
  }

  const consoleOutput = `
================================================================================
                    EVENT_EASE LOAD TEST SUMMARY REPORT
================================================================================
Test Suite:           ${testName}
Peak Virtual Users:   ${vus} VUs
Total Requests:       ${totalRequests} requests
Throughput:           ${reqsPerSec} req/s
Failed Requests:      ${failureRate}% (Failed Count: ${failedRequestsCount} / ${totalRequests})
Checks Pass Rate:     ${checksPassRate}% (${checksPassed} passed, ${checksFailed} failed)

--- LATENCY BREAKDOWN (ms) ---
Average Response:     ${avg} ms
50th Percentile (p50):${p50} ms
90th Percentile (p90):${p90} ms
95th Percentile (p95):${p95} ms
99th Percentile (p99):${p99} ms
Max Response Time:    ${max} ms
${failureBreakdown}${checksBreakdown}
================================================================================
`;

  let failureHtmlSection = '';
  if (failedRequestsCount > 0 || timeouts > 0 || gatewayErrors > 0) {
    failureHtmlSection = `
  <div class="card">
    <h2>Failure Classification</h2>
    <table>
      <tr><th>Category</th><th>Count</th><th>Description</th></tr>
      <tr><td>Timeouts (status=0)</td><td>${timeouts}</td><td>Connection pool queue starvation or network timeout</td></tr>
      <tr><td>Gateway Errors (502/503/504)</td><td>${gatewayErrors}</td><td>Upstream Kong/PgBouncer capacity limit rejection</td></tr>
      <tr><td>Server Errors (5xx)</td><td>${serverErrors}</td><td>Internal database or Edge Function error</td></tr>
      <tr><td>Client Errors (4xx)</td><td>${clientErrors}</td><td>Authentication, RLS, or bad parameter errors</td></tr>
    </table>
  </div>
`;
  }

  const htmlReport = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <title>EventEase - ${testName} Report</title>
  <style>
    body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif; background: #0f172a; color: #f8fafc; padding: 24px; }
    .card { background: #1e293b; border-radius: 12px; padding: 20px; margin-bottom: 20px; box-shadow: 0 4px 6px -1px rgba(0,0,0,0.3); }
    h1, h2 { margin-top: 0; color: #38bdf8; }
    .grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 16px; margin-bottom: 20px; }
    .metric { background: #334155; padding: 16px; border-radius: 8px; text-align: center; }
    .metric-val { font-size: 28px; font-weight: bold; color: #e2e8f0; margin-top: 8px; }
    .good { color: #4ade80; }
    .warn { color: #facc15; }
    .bad { color: #f87171; }
    table { width: 100%; border-collapse: collapse; margin-top: 12px; }
    th, td { text-align: left; padding: 12px; border-bottom: 1px solid #475569; }
    th { color: #94a3b8; }
  </style>
</head>
<body>
  <div class="card">
    <h1>EventEase Performance Report: ${testName}</h1>
    <p>Generated: ${new Date().toUTCString()}</p>
  </div>

  <div class="grid">
    <div class="metric"><div>Peak VUs</div><div class="metric-val">${vus}</div></div>
    <div class="metric"><div>Throughput</div><div class="metric-val">${reqsPerSec} <span style="font-size:14px">req/s</span></div></div>
    <div class="metric"><div>p95 Latency</div><div class="metric-val ${parseFloat(p95) > 1200 ? 'warn' : 'good'}">${p95} <span style="font-size:14px">ms</span></div></div>
    <div class="metric"><div>Error Rate</div><div class="metric-val ${parseFloat(failureRate) > 1 ? 'bad' : 'good'}">${failureRate}%</div></div>
  </div>
${failureHtmlSection}
  <div class="card">
    <h2>Detailed Latency Percentiles</h2>
    <table>
      <tr><th>Metric</th><th>Latency (ms)</th><th>SLA Target</th><th>Status</th></tr>
      <tr><td>p50 (Median)</td><td>${p50} ms</td><td>&lt; 400 ms</td><td>${parseFloat(p50) <= 400 ? '✅ PASS' : '⚠️ HIGH'}</td></tr>
      <tr><td>p90</td><td>${p90} ms</td><td>&lt; 800 ms</td><td>${parseFloat(p90) <= 800 ? '✅ PASS' : '⚠️ HIGH'}</td></tr>
      <tr><td>p95</td><td>${p95} ms</td><td>&lt; 1200 ms</td><td>${parseFloat(p95) <= 1200 ? '✅ PASS' : '⚠️ HIGH'}</td></tr>
      <tr><td>p99</td><td>${p99} ms</td><td>&lt; 2500 ms</td><td>${parseFloat(p99) <= 2500 ? '✅ PASS' : '⚠️ HIGH'}</td></tr>
      <tr><td>Max Latency</td><td>${max} ms</td><td>-</td><td>-</td></tr>
      <tr><td>Average</td><td>${avg} ms</td><td>-</td><td>-</td></tr>
    </table>
  </div>
</body>
</html>
`;

  return {
    stdout: consoleOutput,
    'reports/summary.json': JSON.stringify(data, null, 2),
    'reports/summary.html': htmlReport,
  };
}
