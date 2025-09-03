#!/bin/bash

# Simple script to start the monitoring stack for local development
# Usage: ./start-monitoring.sh

set -e

echo "🚀 Starting Pulse-Check Monitoring Stack for Local Development"
echo "============================================================="

# Check if docker-compose exists
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed or not in PATH"
    exit 1
fi

if ! command -v docker-compose &> /dev/null && ! docker compose version &> /dev/null; then
    echo "❌ Docker Compose is not installed or not in PATH"
    exit 1
fi

# Stop any existing containers
echo "🛑 Stopping existing containers..."
docker compose down -v 2>/dev/null || true

# Clean up orphaned containers
echo "🧹 Cleaning up..."
docker container prune -f 2>/dev/null || true

# Set environment variables for local development
export BRANCH=${BRANCH:-"local-dev"}
export APP_LOG_PATH="/var/log/app/app.log"

echo "🔧 Configuration:"
echo "  - Branch: $BRANCH"
echo "  - Environment: Local Development"

# Start all services
echo "🏗️ Starting monitoring stack..."
docker compose up -d

echo "⏳ Waiting for services to initialize..."
echo "   This may take 30-60 seconds for all services to be ready..."

# Wait a bit for services to start
sleep 15

# Check service health
echo ""
echo "🔍 Checking service health..."

# Function to check service
check_service() {
    local name=$1
    local url=$2
    local timeout=${3:-10}
    
    printf "   %-12s " "$name:"
    
    for i in $(seq 1 $timeout); do
        if curl -s -f "$url" >/dev/null 2>&1; then
            echo "✅ Ready"
            return 0
        fi
        sleep 1
    done
    
    echo "❌ Not ready"
    return 1
}

# Check all services
check_service "Application" "http://localhost:8000/health" 15
check_service "Prometheus" "http://localhost:9090/-/ready" 10
check_service "Grafana" "http://localhost:3000/api/health" 15
check_service "Loki" "http://localhost:3100/ready" 10

# Additional Grafana check
echo ""
echo "📊 Checking Grafana dashboard provisioning..."
sleep 10  # Give Grafana time to load dashboards

DASHBOARD_COUNT=$(curl -s -u admin:admin "http://localhost:3000/api/search" 2>/dev/null | jq length 2>/dev/null || echo "0")
echo "   Found $DASHBOARD_COUNT dashboard(s)"

# Generate some test data
echo ""
echo "🧪 Generating test data..."
for i in {1..10}; do
    curl -s http://localhost:8000/hello >/dev/null &
    curl -s http://localhost:8000/health >/dev/null &
done
wait

echo "   Generated initial test traffic"

# Display access information
echo ""
echo "🎉 Monitoring stack is ready!"
echo ""
echo "📍 Access Points:"
echo "   🎯 Grafana Dashboard: http://localhost:3000"
echo "      └── Username: admin"
echo "      └── Password: admin"
echo ""
echo "   📊 Prometheus Metrics: http://localhost:9090"
echo "   📋 Application Logs: http://localhost:3100"
echo "   🔍 Trace Analysis: http://localhost:3200"
echo "   🏥 App Health Check: http://localhost:8000/health"
echo ""
echo "💡 Troubleshooting:"
echo "   • If dashboards are empty, wait a few minutes for data collection"
echo "   • Run './scripts/fix_local_grafana.sh' if you encounter issues"
echo "   • Generate more test data: curl http://localhost:8000/hello"
echo ""
echo "🛑 To stop: docker compose down"
echo ""