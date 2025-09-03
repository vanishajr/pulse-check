#!/bin/bash
# Enhanced PR Report Generator
# Usage: ./generate_pr_report.sh [pr_number] [branch] [format]

set -e

# Parameters
PR_NUMBER="${1:-$PR_NUMBER}"
BRANCH="${2:-$(git branch --show-current)}"
FORMAT="${3:-markdown}" # markdown, html, json
COMMIT_SHA="${4:-$(git rev-parse HEAD)}"

# Configuration
PROMETHEUS_URL="${PROMETHEUS_URL:-http://localhost:9090}"
GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
GRAFANA_USER="${GRAFANA_USER:-admin}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-admin}"

# Report directory
REPORT_DIR="pr-reports"
mkdir -p "$REPORT_DIR"

echo "📊 Generating comprehensive PR report for #$PR_NUMBER (branch: $BRANCH)"

# Function to query Prometheus with error handling
query_prometheus() {
    local query="$1"
    local default="$2"
    
    result=$(curl -s "$PROMETHEUS_URL/api/v1/query?query=$(echo "$query" | sed 's/ /%20/g')" 2>/dev/null | jq -r '.data.result[0].value[1] // "'"$default"'"' 2>/dev/null)
    echo "${result:-$default}"
}

# Function to query Prometheus for range data
query_prometheus_range() {
    local query="$1"
    local duration="${2:-5m}"
    local step="${3:-30s}"
    
    curl -s "$PROMETHEUS_URL/api/v1/query_range?query=$(echo "$query" | sed 's/ /%20/g')&start=$(date -d "$duration ago" +%s)&end=$(date +%s)&step=$step" 2>/dev/null
}

echo "🔍 Collecting comprehensive metrics..."

# Core Performance Metrics
TOTAL_REQUESTS=$(query_prometheus "sum(app_requests_total{branch=\"$BRANCH\"})" "0")
REQUEST_RATE=$(query_prometheus "sum(rate(app_requests_total{branch=\"$BRANCH\"}[1m]))" "0")
P50_LATENCY=$(query_prometheus "histogram_quantile(0.50,sum(rate(app_request_duration_seconds_bucket{branch=\"$BRANCH\"}[5m]))by(le))" "0")
P95_LATENCY=$(query_prometheus "histogram_quantile(0.95,sum(rate(app_request_duration_seconds_bucket{branch=\"$BRANCH\"}[5m]))by(le))" "0")
P99_LATENCY=$(query_prometheus "histogram_quantile(0.99,sum(rate(app_request_duration_seconds_bucket{branch=\"$BRANCH\"}[5m]))by(le))" "0")
ERROR_RATE=$(query_prometheus "sum(rate(app_requests_total{branch=\"$BRANCH\",status=~\"4..|5..\"}[5m]))/sum(rate(app_requests_total{branch=\"$BRANCH\"}[5m]))*100" "0")
SUCCESS_RATE=$(query_prometheus "sum(rate(app_requests_total{branch=\"$BRANCH\",status=~\"2..\"}[5m]))/sum(rate(app_requests_total{branch=\"$BRANCH\"}[5m]))*100" "100")

# Endpoint Analysis
ENDPOINTS=$(curl -s "$PROMETHEUS_URL/api/v1/label/endpoint/values" | jq -r '.data[]' 2>/dev/null | grep -v '^$' || echo "/health /hello")

echo "Collected metrics for $TOTAL_REQUESTS total requests"

# Performance Analysis
get_performance_grade() {
    local p95="$1"
    local error_rate="$2"
    
    if (( $(echo "$p95 > 2.0 || $error_rate > 5" | bc -l 2>/dev/null || echo "0") )); then
        echo " Poor"
    elif (( $(echo "$p95 > 1.0 || $error_rate > 1" | bc -l 2>/dev/null || echo "0") )); then
        echo " Fair"
    elif (( $(echo "$p95 > 0.5" | bc -l 2>/dev/null || echo "0") )); then
        echo " Good"
    else
        echo " Excellent"
    fi
}

PERFORMANCE_GRADE=$(get_performance_grade "$P95_LATENCY" "$ERROR_RATE")

# Create Grafana snapshot with extended retention
create_enhanced_snapshot() {
    local snapshot_name="PR-$PR_NUMBER Comprehensive Report ($BRANCH)"
    
    DASHBOARD_JSON=$(cat << EOF
{
  "dashboard": {
    "title": "$snapshot_name",
    "tags": ["pr-$PR_NUMBER", "$BRANCH", "comprehensive-report"],
    "time": {"from": "now-15m", "to": "now"},
    "refresh": "5s",
    "panels": [
      {
        "title": "Request Rate Over Time",
        "type": "timeseries",
        "targets": [{"expr": "sum(rate(app_requests_total{branch=\"$BRANCH\"}[1m])) by (endpoint)", "refId": "A"}],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "title": "Response Time Percentiles",
        "type": "timeseries",
        "targets": [
          {"expr": "histogram_quantile(0.50, sum(rate(app_request_duration_seconds_bucket{branch=\"$BRANCH\"}[1m])) by (le))", "refId": "A", "legendFormat": "P50"},
          {"expr": "histogram_quantile(0.95, sum(rate(app_request_duration_seconds_bucket{branch=\"$BRANCH\"}[1m])) by (le))", "refId": "B", "legendFormat": "P95"},
          {"expr": "histogram_quantile(0.99, sum(rate(app_request_duration_seconds_bucket{branch=\"$BRANCH\"}[1m])) by (le))", "refId": "C", "legendFormat": "P99"}
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      },
      {
        "title": "Error Rate",
        "type": "stat",
        "targets": [{"expr": "sum(rate(app_requests_total{branch=\"$BRANCH\",status=~\"4..|5..\"}[5m]))/sum(rate(app_requests_total{branch=\"$BRANCH\"}[5m]))*100", "refId": "A"}],
        "gridPos": {"h": 6, "w": 6, "x": 0, "y": 8}
      },
      {
        "title": "Total Requests",
        "type": "stat",
        "targets": [{"expr": "sum(app_requests_total{branch=\"$BRANCH\"})", "refId": "A"}],
        "gridPos": {"h": 6, "w": 6, "x": 6, "y": 8}
      }
    ]
  }
}
EOF
)
    
    SNAPSHOT_RESPONSE=$(curl -s -X POST "$GRAFANA_URL/api/snapshots" \
        -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
        -H "Content-Type: application/json" \
        -d "{
              \"name\": \"$snapshot_name\",
              \"expires\": 604800,
              \"external\": false,
              $DASHBOARD_JSON
            }")
    
    SNAPSHOT_KEY=$(echo "$SNAPSHOT_RESPONSE" | jq -r '.key // empty')
    if [ -n "$SNAPSHOT_KEY" ]; then
        echo "$GRAFANA_URL/dashboard/snapshot/$SNAPSHOT_KEY"
    else
        echo ""
    fi
}

echo "📸 Creating enhanced Grafana snapshot..."
SNAPSHOT_URL=$(create_enhanced_snapshot)

# Generate timestamp
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S UTC')
REPORT_ID="pr-$PR_NUMBER-$(date +%s)"

# Format numbers for display
format_number() {
    printf "%.3f" "$1" 2>/dev/null || echo "$1"
}

format_percentage() {
    printf "%.2f" "$1" 2>/dev/null || echo "$1"
}

P50_FORMATTED=$(format_number "$P50_LATENCY")
P95_FORMATTED=$(format_number "$P95_LATENCY")
P99_FORMATTED=$(format_number "$P99_LATENCY")
ERROR_RATE_FORMATTED=$(format_percentage "$ERROR_RATE")
SUCCESS_RATE_FORMATTED=$(format_percentage "$SUCCESS_RATE")
REQUEST_RATE_FORMATTED=$(format_number "$REQUEST_RATE")

# Generate reports in different formats
case "$FORMAT" in
    "html")
        REPORT_FILE="$REPORT_DIR/pr-$PR_NUMBER-report.html"
        cat > "$REPORT_FILE" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>PR #$PR_NUMBER Performance Report</title>
    <style>
        body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif; margin: 40px; }
        .header { background: #f8f9fa; padding: 20px; border-radius: 8px; margin-bottom: 30px; }
        .metrics-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(250px, 1fr)); gap: 20px; margin: 20px 0; }
        .metric-card { background: white; border: 1px solid #e1e5e9; border-radius: 8px; padding: 20px; }
        .metric-value { font-size: 2em; font-weight: bold; color: #0366d6; }
        .metric-label { color: #586069; margin-top: 5px; }
        .grade-excellent { color: #28a745; }
        .grade-good { color: #28a745; }
        .grade-fair { color: #ffc107; }
        .grade-poor { color: #dc3545; }
        .snapshot-link { background: #0366d6; color: white; padding: 12px 24px; border-radius: 6px; text-decoration: none; display: inline-block; margin: 20px 0; }
    </style>
</head>
<body>
    <div class="header">
        <h1>Performance Report for PR #$PR_NUMBER</h1>
        <p><strong>Branch:</strong> <code>$BRANCH</code> | <strong>Commit:</strong> <code>${COMMIT_SHA:0:8}</code></p>
        <p><strong>Generated:</strong> $TIMESTAMP | <strong>Performance Grade:</strong> <span class="grade-$(echo "$PERFORMANCE_GRADE" | tr '🔴🟡🟢' 'poor fair good' | awk '{print $2}')">$PERFORMANCE_GRADE</span></p>
    </div>
    
    <h2> Performance Metrics</h2>
    <div class="metrics-grid">
        <div class="metric-card">
            <div class="metric-value">$TOTAL_REQUESTS</div>
            <div class="metric-label">Total Requests Processed</div>
        </div>
        <div class="metric-card">
            <div class="metric-value">${REQUEST_RATE_FORMATTED}/s</div>
            <div class="metric-label">Current Request Rate</div>
        </div>
        <div class="metric-card">
            <div class="metric-value">${P95_FORMATTED}s</div>
            <div class="metric-label">95th Percentile Latency</div>
        </div>
        <div class="metric-card">
            <div class="metric-value">${ERROR_RATE_FORMATTED}%</div>
            <div class="metric-label">Error Rate</div>
        </div>
    </div>
    
    <h3> Detailed Latency Analysis</h3>
    <table style="width: 100%; border-collapse: collapse;">
        <tr style="background: #f8f9fa;">
            <th style="padding: 12px; text-align: left; border: 1px solid #e1e5e9;">Percentile</th>
            <th style="padding: 12px; text-align: left; border: 1px solid #e1e5e9;">Response Time</th>
            <th style="padding: 12px; text-align: left; border: 1e5e9;">Status</th>
        </tr>
        <tr><td style="padding: 12px; border: 1px solid #e1e5e9;">P50 (Median)</td><td style="padding: 12px; border: 1px solid #e1e5e9;">${P50_FORMATTED}s</td><td style="padding: 12px; border: 1px solid #e1e5e9;">$([ $(echo "$P50_LATENCY < 0.2" | bc -l) = 1 ] && echo "✅ Excellent" || echo "⚠️ Monitor")</td></tr>
        <tr><td style="padding: 12px; border: 1px solid #e1e5e9;">P95</td><td style="padding: 12px; border: 1px solid #e1e5e9;">${P95_FORMATTED}s</td><td style="padding: 12px; border: 1px solid #e1e5e9;">$([ $(echo "$P95_LATENCY < 1.0" | bc -l) = 1 ] && echo "✅ Good" || echo "❌ Needs Attention")</td></tr>
        <tr><td style="padding: 12px; border: 1px solid #e1e5e9;">P99</td><td style="padding: 12px; border: 1px solid #e1e5e9;">${P99_FORMATTED}s</td><td style="padding: 12px; border: 1px solid #e1e5e9;">$([ $(echo "$P99_LATENCY < 2.0" | bc -l) = 1 ] && echo "✅ Acceptable" || echo "❌ High Tail Latency")</td></tr>
    </table>
    
    $([ -n "$SNAPSHOT_URL" ] && echo "<h2> Live Dashboard</h2><a href=\"$SNAPSHOT_URL\" class=\"snapshot-link\">View Interactive Grafana Dashboard</a>" || echo "<h2>⚠️ Dashboard Unavailable</h2><p>Grafana snapshot could not be generated.</p>")
    
    <h2>Recommendations</h2>
    <ul>
$([ $(echo "$P95_LATENCY > 1.0" | bc -l) = 1 ] && echo "        <li>❗ <strong>High P95 latency detected</strong> - Review application bottlenecks and database queries</li>")
$([ $(echo "$ERROR_RATE > 1" | bc -l) = 1 ] && echo "        <li>❗ <strong>Elevated error rate</strong> - Investigate error patterns and fix issues before merging</li>")
$([ $(echo "$P95_LATENCY <= 0.5 && $ERROR_RATE < 0.1" | bc -l) = 1 ] && echo "        <li>✅ <strong>Excellent performance</strong> - No issues detected, ready for merge</li>")
        <li>Monitor performance trends after merging to main branch</li>
        <li>Consider load testing for higher confidence</li>
    </ul>
    
    <footer style="margin-top: 40px; padding-top: 20px; border-top: 1px solid #e1e5e9; color: #586069; font-size: 0.9em;">
        Report ID: $REPORT_ID | Generated by PR Performance Monitor
    </footer>
</body>
</html>
EOF
        echo " HTML report generated: $REPORT_FILE"
        ;;
        
    "json")
        REPORT_FILE="$REPORT_DIR/pr-$PR_NUMBER-report.json"
        cat > "$REPORT_FILE" << EOF
{
  "reportId": "$REPORT_ID",
  "timestamp": "$TIMESTAMP",
  "pr": {
    "number": $PR_NUMBER,
    "branch": "$BRANCH",
    "commit": "$COMMIT_SHA"
  },
  "performance": {
    "grade": "$PERFORMANCE_GRADE",
    "metrics": {
      "totalRequests": $TOTAL_REQUESTS,
      "requestRate": $REQUEST_RATE_FORMATTED,
      "latency": {
        "p50": $P50_FORMATTED,
        "p95": $P95_FORMATTED,
        "p99": $P99_FORMATTED
      },
      "errorRate": $ERROR_RATE_FORMATTED,
      "successRate": $SUCCESS_RATE_FORMATTED
    }
  },
  "dashboard": {
    "snapshotUrl": "$SNAPSHOT_URL"
  },
  "analysis": {
    "performanceIssues": $([ $(echo "$P95_LATENCY > 1.0" | bc -l) = 1 ] && echo "true" || echo "false"),
    "errorIssues": $([ $(echo "$ERROR_RATE > 1" | bc -l) = 1 ] && echo "true" || echo "false"),
    "readyForMerge": $([ $(echo "$P95_LATENCY <= 1.0 && $ERROR_RATE < 1" | bc -l) = 1 ] && echo "true" || echo "false")
  }
}
EOF
        echo "JSON report generated: $REPORT_FILE"
        ;;
        
    *)  # Default: markdown
        REPORT_FILE="$REPORT_DIR/pr-$PR_NUMBER-report.md"
        cat > "$REPORT_FILE" << EOF
#  Performance Report for PR #$PR_NUMBER

**Branch:** \`$BRANCH\`  
**Commit:** \`${COMMIT_SHA:0:8}\`  
**Generated:** $TIMESTAMP  
**Performance Grade:** $PERFORMANCE_GRADE

## Executive Summary

| Metric | Value | Status |
|--------|-------|--------|
| Total Requests | $TOTAL_REQUESTS | $([ "$TOTAL_REQUESTS" -gt "0" ] && echo "✅" || echo "⚠️") |
| Request Rate | ${REQUEST_RATE_FORMATTED}/s | $([ $(echo "$REQUEST_RATE > 0" | bc -l) = 1 ] && echo "✅" || echo "⚠️") |
| P95 Response Time | ${P95_FORMATTED}s | $([ $(echo "$P95_LATENCY < 1.0" | bc -l) = 1 ] && echo "✅" || echo "❌") |
| Error Rate | ${ERROR_RATE_FORMATTED}% | $([ $(echo "$ERROR_RATE < 1" | bc -l) = 1 ] && echo "✅" || echo "❌") |

##  Detailed Performance Analysis

### Response Time Distribution
- **P50 (Median):** ${P50_FORMATTED}s
- **P95:** ${P95_FORMATTED}s  
- **P99:** ${P99_FORMATTED}s

### Reliability Metrics
- **Success Rate:** ${SUCCESS_RATE_FORMATTED}%
- **Error Rate:** ${ERROR_RATE_FORMATTED}%

$([ -n "$SNAPSHOT_URL" ] && echo "##  Interactive Dashboard

[🔗 View Live Grafana Dashboard]($SNAPSHOT_URL)

*Dashboard available for 7 days*" || echo "## ⚠️ Dashboard Unavailable

Grafana snapshot could not be generated. Check logs for details.")

## Performance Assessment

$([ $(echo "$P95_LATENCY <= 0.5 && $ERROR_RATE < 0.1" | bc -l) = 1 ] && echo "### ✅ Excellent Performance
- Response times are well within acceptable limits
- Error rate is minimal
- **Recommendation:** Ready for merge" || 
[ $(echo "$P95_LATENCY <= 1.0 && $ERROR_RATE < 1" | bc -l) = 1 ] && echo "### 🟢 Good Performance
- Response times are acceptable
- Error rate is within limits  
- **Recommendation:** Safe to merge with monitoring" ||
[ $(echo "$P95_LATENCY <= 2.0 && $ERROR_RATE < 5" | bc -l) = 1 ] && echo "### 🟡 Fair Performance
- Response times need attention
- Error rate is elevated
- **Recommendation:** Consider optimization before merge" ||
echo "###  Poor Performance
- Response times exceed acceptable thresholds
- High error rate detected
- **Recommendation:** Performance optimization required")

## 🔍 Recommendations

$([ $(echo "$P95_LATENCY > 1.0" | bc -l) = 1 ] && echo "-  **High latency detected** - Review database queries and application bottlenecks")
$([ $(echo "$ERROR_RATE > 1" | bc -l) = 1 ] && echo "- **Elevated error rate** - Investigate error patterns and add proper error handling")
$([ $(echo "$P99_LATENCY > 3.0" | bc -l) = 1 ] && echo "-  **High tail latency** - Check for resource contention and optimize slow operations")
-  Monitor performance trends after merging
-  Consider running load tests for critical changes
-  Set up performance alerts for production

---
*Report ID: $REPORT_ID*  
*Generated by PR Performance Monitor *
EOF
        echo "📝 Markdown report generated: $REPORT_FILE"
        ;;
esac

# Save report path for GitHub Actions
if [ -n "$GITHUB_ENV" ]; then
    echo "REPORT_FILE=$REPORT_FILE" >> $GITHUB_ENV
    echo "REPORT_URL=$SNAPSHOT_URL" >> $GITHUB_ENV
    echo "PERFORMANCE_GRADE=$PERFORMANCE_GRADE" >> $GITHUB_ENV
fi

echo " Comprehensive PR report generated!"
echo " Report location: $REPORT_FILE"
[ -n "$SNAPSHOT_URL" ] && echo "🔗 Dashboard URL: $SNAPSHOT_URL"

# Optional: Upload to artifact storage or S3
if [ "$UPLOAD_REPORTS" = "true" ]; then
    echo " Uploading report to artifact storage..."
    # Add your upload logic here
fi