#!/bin/bash

# Local Dashboard Testing Script
# This script mimics what the GitHub Actions workflow does

echo "🚀 Starting local dashboard testing..."
echo "========================================"

# Set branch for testing
export BRANCH=$(git branch --show-current)
echo "📋 Testing branch: $BRANCH"

# Start the monitoring stack
echo "🏁 Starting Docker Compose stack..."
docker compose up -d

# Wait for services
echo "⏳ Waiting for services to start (60 seconds)..."
sleep 60

# Check services
echo "🔍 Checking service health..."
docker compose ps

# Test endpoints
echo "🧪 Testing application endpoints..."

# Basic health check
if curl -f http://localhost:8000/health; then
    echo "✅ Health endpoint working"
else
    echo "❌ Health endpoint failed"
fi

# Test hello endpoint
if curl -f http://localhost:8000/hello; then
    echo "✅ Hello endpoint working"
else
    echo "❌ Hello endpoint failed"
fi

# Test Prometheus
if curl -f http://localhost:9090/-/ready; then
    echo "✅ Prometheus ready"
else
    echo "❌ Prometheus not ready"
fi

# Test Grafana
if curl -f http://localhost:3000/api/health; then
    echo "✅ Grafana accessible"
else
    echo "❌ Grafana not accessible"
fi

# Generate test load
echo ""
echo "🚀 Generating test load..."
echo "📊 This will create metrics for the dashboard"

for round in {1..3}; do
    echo "Load round $round/3..."
    
    # Generate concurrent requests
    for i in {1..15}; do
        curl -s http://localhost:8000/health > /dev/null &
        curl -s http://localhost:8000/hello > /dev/null &
    done
    
    # Some with delays
    for i in {1..5}; do
        curl -s "http://localhost:8000/hello?delay=0.1" > /dev/null &
        curl -s "http://localhost:8000/hello?delay=0.2" > /dev/null &
    done
    
    sleep 2
done

echo "✅ Load generation complete!"
echo ""
echo "🎯 DASHBOARD ACCESS:"
echo "================================"
echo "📊 Grafana Dashboard:"
echo "   URL: http://localhost:3000"
echo "   Username: admin"
echo "   Password: admin"
echo ""
echo "📈 Prometheus:"
echo "   URL: http://localhost:9090"
echo ""
echo "🚀 Application:"
echo "   Health: http://localhost:8000/health"
echo "   Hello: http://localhost:8000/hello"
echo ""
echo "🔍 Dashboards to check:"
echo "   - PR Performance Overview"
echo "   - Latency & Error Analysis"
echo ""
echo "⏰ The environment will stay running until you stop it"
echo "   To stop: docker compose down"
echo "   To stop and cleanup: docker compose down -v"
echo ""
echo "📝 Note: Let the system run for ~30 seconds after load generation"
echo "   to ensure all metrics are collected and visible in dashboards"
echo "================================"

# Keep the script running for a bit more
echo "⏳ Waiting 30 seconds for metrics to propagate..."
sleep 30

echo "🎉 Ready! You can now check the Grafana dashboard!"
echo "💡 Press Ctrl+C to exit this script (Docker will keep running)"

# Keep the script alive
while true; do
    sleep 10
done