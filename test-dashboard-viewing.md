# Dashboard Viewing Test

This is a test file to trigger GitHub Actions so we can view the Grafana dashboard before cleanup.

## Test Purpose
- Trigger the PR monitoring workflow
- Generate sample metrics and logs
- Allow time to manually check the Grafana dashboard
- Test the monitoring system end-to-end

## What to Check While Running
1. **Grafana Dashboard**: http://localhost:3000 (admin/admin)
   - PR Performance Overview
   - Latency & Error Analysis
   - Check if metrics are showing up

2. **Prometheus**: http://localhost:9090
   - Verify metrics collection
   - Check targets status

3. **Application**: http://localhost:8000
   - Health endpoint: http://localhost:8000/health
   - Hello endpoint: http://localhost:8000/hello

## Expected Metrics
- Request counts for /health and /hello endpoints
- Response time percentiles
- Success rates
- Application logs with branch information

## Test Actions
This file will trigger automatic:
1. Docker stack startup
2. Service health checks
3. Load generation (multiple requests)
4. Metrics collection
5. Extended wait period for manual dashboard checking

---
*Created: 2025-01-03 - Dashboard Viewing Test*