#!/bin/bash

# Enhanced PR Comment Generator with Metrics and Snapshots
# Usage: ./post_pr_comment.sh <PR_NUMBER> <BRANCH> <COMMIT_SHA>

set -e

PR_NUMBER="$1"
BRANCH="$2"
COMMIT_SHA="$3"
TIMESTAMP=$(date -Iseconds)
GRAFANA_URL="http://localhost:3000"
GRAFANA_USER="admin"
GRAFANA_PASSWORD="admin"

echo "🤖 Generating comprehensive PR comment for PR #$PR_NUMBER ($BRANCH)..."

# Function to safely get metric with fallback
get_metric() {
    local query="$1"
    local fallback="$2"
    local result
    
    result=$(curl -s "http://localhost:9090/api/v1/query?query=$query" | jq -r '.data.result[0].value[1] // "'$fallback'"' 2>/dev/null || echo "$fallback")
    echo "$result"
}

# Function to format number with proper precision
format_number() {
    local num="$1"
    local precision="$2"
    
    if [ "$num" = "0" ] || [ "$num" = "null" ]; then
        echo "0"
    else
        printf "%.${precision}f" "$num" 2>/dev/null || echo "$num"
    fi
}

# Collect comprehensive metrics
echo "📊 Collecting performance metrics..."

TOTAL_REQUESTS=$(get_metric "sum(app_requests_total{branch=\"$BRANCH\"})" "0")
REQUEST_RATE=$(get_metric "sum(rate(app_requests_total{branch=\"$BRANCH\"}[2m]))" "0")
P50_LATENCY=$(get_metric "histogram_quantile(0.50,sum(rate(app_request_duration_seconds_bucket{branch=\"$BRANCH\"}[5m]))by(le))" "0")
P95_LATENCY=$(get_metric "histogram_quantile(0.95,sum(rate(app_request_duration_seconds_bucket{branch=\"$BRANCH\"}[5m]))by(le))" "0")
P99_LATENCY=$(get_metric "histogram_quantile(0.99,sum(rate(app_request_duration_seconds_bucket{branch=\"$BRANCH\"}[5m]))by(le))" "0")
ERROR_RATE=$(get_metric "sum(rate(app_requests_total{branch=\"$BRANCH\",status=~\"4..|5..\"}[5m]))/sum(rate(app_requests_total{branch=\"$BRANCH\"}[5m]))*100" "0")
SUCCESS_RATE=$(get_metric "sum(rate(app_requests_total{branch=\"$BRANCH\",status=~\"2..\"}[5m]))/sum(rate(app_requests_total{branch=\"$BRANCH\"}[5m]))*100" "100")

# Format metrics for display
FMT_TOTAL_REQUESTS=$(format_number "$TOTAL_REQUESTS" "0")
FMT_REQUEST_RATE=$(format_number "$REQUEST_RATE" "2")
FMT_P50_LATENCY=$(format_number "$(echo "$P50_LATENCY * 1000" | bc -l 2>/dev/null || echo "0")" "2")
FMT_P95_LATENCY=$(format_number "$(echo "$P95_LATENCY * 1000" | bc -l 2>/dev/null || echo "0")" "2")
FMT_P99_LATENCY=$(format_number "$(echo "$P99_LATENCY * 1000" | bc -l 2>/dev/null || echo "0")" "2")
FMT_ERROR_RATE=$(format_number "$ERROR_RATE" "2")
FMT_SUCCESS_RATE=$(format_number "$SUCCESS_RATE" "2")

echo "📸 Creating Grafana snapshots..."

# Create overview snapshot
OVERVIEW_SNAPSHOT_URL=""
if command -v jq >/dev/null; then
    SNAPSHOT_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
        -X POST "$GRAFANA_URL/api/snapshots" \
        -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
        -H "Content-Type: application/json" \
        -d '{
              "name": "PR-'$PR_NUMBER' Overview ('$BRANCH')",
              "expires": 604800,
              "external": false,
              "dashboard": {
                "title": "PR-'$PR_NUMBER' Performance Overview",
                "tags": ["pr-'$PR_NUMBER'", "'$BRANCH'"],
                "time": {"from": "now-30m", "to": "now"},
                "refresh": "30s"
              }
            }' 2>/dev/null)
    
    SNAPSHOT_BODY=$(echo "$SNAPSHOT_RESPONSE" | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')
    SNAPSHOT_STATUS=$(echo "$SNAPSHOT_RESPONSE" | grep -o -E "[0-9]{3}$")
    
    if [ "$SNAPSHOT_STATUS" = "200" ]; then
        SNAPSHOT_KEY=$(echo "$SNAPSHOT_BODY" | jq -r '.key // empty')
        if [ -n "$SNAPSHOT_KEY" ] && [ "$SNAPSHOT_KEY" != "null" ]; then
            OVERVIEW_SNAPSHOT_URL="$GRAFANA_URL/dashboard/snapshot/$SNAPSHOT_KEY"
            echo "✅ Overview snapshot created: $OVERVIEW_SNAPSHOT_URL"
        fi
    fi
fi

# Performance grading logic
grade_performance() {
    local p95="$1"
    local error_rate="$2"
    
    # Convert to comparable format
    local p95_ms=$(echo "$p95 * 1000" | bc -l 2>/dev/null || echo "999999")
    
    if (( $(echo "$p95_ms <= 100 && $error_rate < 0.1" | bc -l 2>/dev/null || echo 0) )); then
        echo "🟢 Excellent"
    elif (( $(echo "$p95_ms <= 500 && $error_rate < 1" | bc -l 2>/dev/null || echo 0) )); then
        echo "🟡 Good"
    elif (( $(echo "$p95_ms <= 1000 && $error_rate < 5" | bc -l 2>/dev/null || echo 0) )); then
        echo "🟠 Fair"
    else
        echo "🔴 Needs Improvement"
    fi
}

PERFORMANCE_GRADE=$(grade_performance "$P95_LATENCY" "$ERROR_RATE")

# Generate comprehensive comment
echo "📝 Generating PR comment..."

cat > /tmp/pr_comment.md << EOF
## 🚀 Complete Performance Analysis

**PR #$PR_NUMBER** | **Branch:** `$BRANCH` | **Commit:** `${COMMIT_SHA:0:8}` | **Generated:** $(date '+%Y-%m-%d %H:%M:%S UTC')

---

### 📊 **Performance Summary**

| Metric | Value | Status |
|--------|--------|--------|
| **Overall Grade** | $PERFORMANCE_GRADE | $([ "$PERFORMANCE_GRADE" = "🟢 Excellent" ] && echo "✅ Ready for merge" || [ "$PERFORMANCE_GRADE" = "🟡 Good" ] && echo "✅ Ready for merge" || echo "⚠️ Review recommended") |
| **Total Requests** | $FMT_TOTAL_REQUESTS | $([ "$FMT_TOTAL_REQUESTS" -gt "50" ] && echo "✅" || echo "ℹ️") |
| **Request Rate** | $FMT_REQUEST_RATE req/sec | $([ "$(echo "$REQUEST_RATE > 0" | bc -l 2>/dev/null || echo 0)" = "1" ] && echo "✅" || echo "ℹ️") |
| **Success Rate** | $FMT_SUCCESS_RATE% | $([ "$(echo "$SUCCESS_RATE > 95" | bc -l 2>/dev/null || echo 0)" = "1" ] && echo "✅" || echo "⚠️") |
| **Error Rate** | $FMT_ERROR_RATE% | $([ "$(echo "$ERROR_RATE < 1" | bc -l 2>/dev/null || echo 0)" = "1" ] && echo "✅" || echo "⚠️") |

### ⚡ **Latency Breakdown**

| Percentile | Latency | Target | Status |
|------------|---------|--------|--------|
| **P50 (Median)** | ${FMT_P50_LATENCY}ms | < 50ms | $([ "$(echo "$P50_LATENCY * 1000 < 50" | bc -l 2>/dev/null || echo 0)" = "1" ] && echo "✅" || [ "$(echo "$P50_LATENCY * 1000 < 200" | bc -l 2>/dev/null || echo 0)" = "1" ] && echo "🟡" || echo "🔴") |
| **P95** | ${FMT_P95_LATENCY}ms | < 200ms | $([ "$(echo "$P95_LATENCY * 1000 < 200" | bc -l 2>/dev/null || echo 0)" = "1" ] && echo "✅" || [ "$(echo "$P95_LATENCY * 1000 < 500" | bc -l 2>/dev/null || echo 0)" = "1" ] && echo "🟡" || echo "🔴") |
| **P99** | ${FMT_P99_LATENCY}ms | < 500ms | $([ "$(echo "$P99_LATENCY * 1000 < 500" | bc -l 2>/dev/null || echo 0)" = "1" ] && echo "✅" || [ "$(echo "$P99_LATENCY * 1000 < 1000" | bc -l 2>/dev/null || echo 0)" = "1" ] && echo "🟡" || echo "🔴") |

### 📈 **Interactive Dashboards**

EOF

# Add dashboard links if available
if [ -n "$OVERVIEW_SNAPSHOT_URL" ]; then
    cat >> /tmp/pr_comment.md << EOF
🎯 **[View Performance Overview]($OVERVIEW_SNAPSHOT_URL)** - Complete metrics dashboard

EOF
else
    cat >> /tmp/pr_comment.md << EOF
🎯 **[View Live Grafana Dashboard](http://localhost:3000)** (admin/admin) - Real-time metrics

EOF
fi

cat >> /tmp/pr_comment.md << EOF
### 🔍 **Quick Access Links**

- 📊 [Prometheus Metrics](http://localhost:9090) - Raw metrics data  
- 📋 [Application Logs](http://localhost:3100) - Detailed request logs
- 🔍 [Trace Analysis](http://localhost:3200) - Request tracing

### 💡 **Performance Recommendations**

EOF

# Add performance recommendations based on metrics
if [ "$(echo "$P95_LATENCY * 1000 > 500" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
    cat >> /tmp/pr_comment.md << EOF
- ⚠️ **High P95 latency detected** (${FMT_P95_LATENCY}ms) - Consider optimizing slow endpoints
EOF
fi

if [ "$(echo "$ERROR_RATE > 1" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
    cat >> /tmp/pr_comment.md << EOF
- ⚠️ **Elevated error rate** (${FMT_ERROR_RATE}%) - Review error handling and validation
EOF
fi

if [ "$(echo "$SUCCESS_RATE < 99" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
    cat >> /tmp/pr_comment.md << EOF
- ⚠️ **Success rate below 99%** (${FMT_SUCCESS_RATE}%) - Investigate failing requests
EOF
fi

if [ "$(echo "$P95_LATENCY * 1000 <= 200 && $ERROR_RATE < 1" | bc -l 2>/dev/null || echo 0)" = "1" ]; then
    cat >> /tmp/pr_comment.md << EOF
- ✅ **Excellent performance metrics** - This PR meets all performance targets!
EOF
fi

cat >> /tmp/pr_comment.md << EOF

### 🏗️ **Infrastructure Status**

| Service | Status | Endpoint |
|---------|--------|---------|
| Application | $(curl -s http://localhost:8000/health >/dev/null 2>&1 && echo "🟢 Healthy" || echo "🔴 Down") | http://localhost:8000 |
| Prometheus | $(curl -s http://localhost:9090/-/ready >/dev/null 2>&1 && echo "🟢 Ready" || echo "🔴 Down") | http://localhost:9090 |
| Grafana | $(curl -s http://localhost:3000/api/health >/dev/null 2>&1 && echo "🟢 Available" || echo "🔴 Down") | http://localhost:3000 |
| Loki | $(curl -s http://localhost:3100/ready >/dev/null 2>&1 && echo "🟢 Ready" || echo "🔴 Down") | http://localhost:3100 |

---

<details>
<summary>📋 <strong>Raw Metrics Data</strong></summary>

\`\`\`json
{
  "prNumber": $PR_NUMBER,
  "branch": "$BRANCH",
  "commit": "$COMMIT_SHA",
  "timestamp": "$TIMESTAMP",
  "metrics": {
    "totalRequests": $TOTAL_REQUESTS,
    "requestRate": $REQUEST_RATE,
    "p50LatencyMs": $FMT_P50_LATENCY,
    "p95LatencyMs": $FMT_P95_LATENCY,
    "p99LatencyMs": $FMT_P99_LATENCY,
    "errorRate": $ERROR_RATE,
    "successRate": $SUCCESS_RATE
  }
}
\`\`\`

</details>

*Generated by Pulse-Check Monitoring System v2.0* 🤖
EOF

echo "✅ PR comment generated successfully"
echo "📄 Comment saved to: /tmp/pr_comment.md"

# Output the comment for GitHub Actions
cat /tmp/pr_comment.md