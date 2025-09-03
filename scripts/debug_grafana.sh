#!/bin/bash
# Grafana Dashboard Debugging Script
# This script helps debug Grafana dashboard and datasource issues

echo "🔍 Grafana Debugging Script"
echo "=========================="

# Check if Docker Compose is running
echo "📋 Checking Docker Compose status..."
if docker compose ps | grep -q "grafana"; then
    echo "✅ Docker Compose services are running"
else
    echo "❌ Docker Compose services are not running"
    echo "💡 Run: docker compose up -d"
    exit 1
fi

echo ""
echo "🌐 Service Status:"
docker compose ps

echo ""
echo "🔗 Testing connectivity..."

# Test Grafana
echo "Testing Grafana (port 3000)..."
if curl -s -f http://localhost:3000/api/health >/dev/null; then
    echo "✅ Grafana is accessible"
else
    echo "❌ Grafana is not accessible"
fi

# Test Prometheus
echo "Testing Prometheus (port 9090)..."
if curl -s -f http://localhost:9090/-/ready >/dev/null; then
    echo "✅ Prometheus is ready"
else
    echo "❌ Prometheus is not ready"
fi

# Test Loki
echo "Testing Loki (port 3100)..."
if curl -s -f http://localhost:3100/ready >/dev/null; then
    echo "✅ Loki is ready"
else
    echo "❌ Loki is not ready"
fi

# Test Application
echo "Testing Application (port 8000)..."
if curl -s -f http://localhost:8000/health >/dev/null; then
    echo "✅ Application is healthy"
else
    echo "❌ Application is not healthy"
fi

# Test Metrics endpoint
echo "Testing Metrics endpoint (port 8001)..."
if curl -s -f http://localhost:8001/metrics >/dev/null; then
    echo "✅ Metrics endpoint is accessible"
else
    echo "❌ Metrics endpoint is not accessible"
fi

echo ""
echo "🔍 Grafana Detailed Analysis..."

# Check Grafana logs
echo "--- Recent Grafana Logs ---"
docker compose logs grafana --tail 20

echo ""
echo "🗂️ Checking Grafana Datasources..."
DATASOURCES=$(curl -s -u admin:admin http://localhost:3000/api/datasources 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "Available datasources:"
    echo "$DATASOURCES" | jq '.[].name' 2>/dev/null || echo "No datasources found or jq not available"
    
    echo ""
    echo "Datasource details:"
    echo "$DATASOURCES" | jq '.[] | {name: .name, type: .type, url: .url}' 2>/dev/null || echo "Cannot parse datasources"
else
    echo "❌ Cannot connect to Grafana API"
fi

echo ""
echo "📊 Checking Grafana Dashboards..."
DASHBOARDS=$(curl -s -u admin:admin http://localhost:3000/api/search 2>/dev/null)
if [ $? -eq 0 ]; then
    DASHBOARD_COUNT=$(echo "$DASHBOARDS" | jq length 2>/dev/null || echo "0")
    echo "Found $DASHBOARD_COUNT dashboards:"
    echo "$DASHBOARDS" | jq '.[].title' 2>/dev/null || echo "No dashboards found or jq not available"
    
    if [ "$DASHBOARD_COUNT" = "0" ]; then
        echo ""
        echo "🔧 Dashboard Troubleshooting:"
        echo "1. Check if dashboard files exist:"
        ls -la grafana/dashboards/ 2>/dev/null || echo "   Dashboard directory not found"
        echo ""
        echo "2. Check dashboard provisioning config:"
        cat grafana/provisioning/dashboards/dashboards.yaml 2>/dev/null || echo "   Provisioning config not found"
        echo ""
        echo "3. Check Grafana container volumes:"
        docker inspect $(docker compose ps -q grafana) --format='{{range .Mounts}}{{.Source}} -> {{.Destination}}{{println}}{{end}}' 2>/dev/null || echo "   Cannot inspect Grafana container"
    fi
else
    echo "❌ Cannot connect to Grafana API"
fi

echo ""
echo "🎯 Checking Prometheus Targets..."
TARGETS=$(curl -s http://localhost:9090/api/v1/targets 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "Prometheus targets:"
    echo "$TARGETS" | jq '.data.activeTargets[] | {job: .labels.job, instance: .labels.instance, health: .health}' 2>/dev/null || echo "Cannot parse targets"
else
    echo "❌ Cannot connect to Prometheus API"
fi

echo ""
echo "📈 Testing Metrics Query..."
METRIC_RESULT=$(curl -s "http://localhost:9090/api/v1/query?query=up" 2>/dev/null)
if [ $? -eq 0 ]; then
    echo "Sample metrics query (up):"
    echo "$METRIC_RESULT" | jq '.data.result[] | {instance: .metric.instance, value: .value[1]}' 2>/dev/null || echo "Cannot parse metrics"
else
    echo "❌ Cannot query Prometheus metrics"
fi

echo ""
echo "📋 Summary & Recommendations:"
echo "========================="

# Check common issues
if docker compose logs grafana --tail 50 | grep -i error >/dev/null 2>&1; then
    echo "⚠️  Found errors in Grafana logs - check above for details"
fi

if [ "$DASHBOARD_COUNT" = "0" ] || [ -z "$DASHBOARD_COUNT" ]; then
    echo "⚠️  No dashboards found - check dashboard provisioning"
    echo "   💡 Solution: Verify grafana/dashboards/ files and provisioning config"
fi

if ! curl -s -f http://localhost:8001/metrics >/dev/null; then
    echo "⚠️  Metrics endpoint not accessible - check application"
    echo "   💡 Solution: Ensure app is running and exposing metrics on port 8001"
fi

echo ""
echo "🔗 Quick Access Links:"
echo "   Grafana: http://localhost:3000 (admin/admin)"
echo "   Prometheus: http://localhost:9090"
echo "   Application: http://localhost:8000"
echo "   Metrics: http://localhost:8001/metrics"

echo ""
echo "🛠️  Common Fixes:"
echo "   1. Restart services: docker compose down && docker compose up -d"
echo "   2. Clear volumes: docker compose down -v && docker compose up -d"
echo "   3. Check file permissions: ls -la grafana/"
echo "   4. View all logs: docker compose logs"