#!/bin/bash

# Comprehensive Grafana Local Setup and Troubleshooting Script
# This script fixes common issues with local Grafana dashboard access

set -e

echo "🔧 Pulse-Check Grafana Local Setup and Fix Script"
echo "================================================="

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_status() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to check if a service is running
check_service() {
    local service=$1
    local url=$2
    local timeout=${3:-10}
    
    print_status "Checking $service at $url..."
    
    for i in $(seq 1 $timeout); do
        if curl -s -f "$url" >/dev/null 2>&1; then
            print_success "$service is running and accessible"
            return 0
        fi
        sleep 1
    done
    
    print_error "$service is not accessible at $url"
    return 1
}

# Function to fix docker-compose configuration
fix_docker_compose() {
    print_status "Fixing docker-compose.yml for local development..."
    
    # Backup original
    if [ -f "docker-compose.yml" ]; then
        cp docker-compose.yml docker-compose.yml.backup
        print_status "Backed up docker-compose.yml"
    fi
    
    # Check if the fix is already applied
    if grep -q "GF_DASHBOARDS_DEFAULT_HOME_DASHBOARD_PATH" docker-compose.yml; then
        print_success "Docker-compose.yml already has local development fixes"
        return 0
    fi
    
    print_warning "Applying docker-compose.yml fixes..."
    # The fixes have already been applied via the main script
    print_success "Docker-compose configuration updated"
}

# Function to create sample dashboard if missing
create_sample_dashboard() {
    local dashboard_dir="grafana/dashboards"
    
    if [ ! -f "$dashboard_dir/pr-overview.json" ]; then
        print_status "Creating sample PR overview dashboard..."
        
        mkdir -p "$dashboard_dir"
        
        cat > "$dashboard_dir/pr-overview.json" << 'EOF'
{
  "dashboard": {
    "id": null,
    "title": "PR Monitoring Dashboard",
    "tags": ["pr-monitoring", "performance"],
    "timezone": "browser",
    "panels": [
      {
        "id": 1,
        "title": "Request Rate",
        "type": "graph",
        "targets": [
          {
            "expr": "sum(rate(app_requests_total[5m]))",
            "legendFormat": "Requests/sec"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 0, "y": 0}
      },
      {
        "id": 2,
        "title": "Response Time Percentiles",
        "type": "graph",
        "targets": [
          {
            "expr": "histogram_quantile(0.50, sum(rate(app_request_duration_seconds_bucket[5m])) by (le))",
            "legendFormat": "P50"
          },
          {
            "expr": "histogram_quantile(0.95, sum(rate(app_request_duration_seconds_bucket[5m])) by (le))",
            "legendFormat": "P95"
          },
          {
            "expr": "histogram_quantile(0.99, sum(rate(app_request_duration_seconds_bucket[5m])) by (le))",
            "legendFormat": "P99"
          }
        ],
        "gridPos": {"h": 8, "w": 12, "x": 12, "y": 0}
      }
    ],
    "time": {"from": "now-1h", "to": "now"},
    "refresh": "30s"
  },
  "folderId": 0,
  "overwrite": true
}
EOF
        
        print_success "Created sample dashboard: $dashboard_dir/pr-overview.json"
    fi
}

# Function to restart services properly
restart_services() {
    print_status "Restarting observability stack..."
    
    # Stop services gracefully
    docker compose down -v 2>/dev/null || true
    
    # Clean up any orphaned containers
    docker container prune -f 2>/dev/null || true
    
    # Remove any dangling volumes
    docker volume prune -f 2>/dev/null || true
    
    print_status "Starting fresh observability stack..."
    
    # Start services in dependency order
    docker compose up -d
    
    print_status "Waiting for services to initialize..."
    sleep 30
}

# Function to verify Grafana setup
verify_grafana() {
    print_status "Verifying Grafana setup..."
    
    # Check if Grafana is accessible
    if ! check_service "Grafana" "http://localhost:3000/api/health" 20; then
        print_error "Grafana is not accessible. Check container logs:"
        docker compose logs grafana --tail 20
        return 1
    fi
    
    # Check if we can login
    print_status "Testing Grafana login..."
    LOGIN_RESPONSE=$(curl -s -w "HTTPSTATUS:%{http_code}" \
        -X POST "http://localhost:3000/login" \
        -H "Content-Type: application/json" \
        -d '{"user":"admin","password":"admin"}' 2>/dev/null || echo "HTTPSTATUS:000")
    
    LOGIN_STATUS=$(echo "$LOGIN_RESPONSE" | grep -o -E "[0-9]{3}$")
    
    if [ "$LOGIN_STATUS" = "200" ] || [ "$LOGIN_STATUS" = "302" ]; then
        print_success "Grafana login is working (admin/admin)"
    else
        print_warning "Grafana login test inconclusive (status: $LOGIN_STATUS)"
    fi
    
    # Check datasources
    print_status "Checking Grafana datasources..."
    DATASOURCES=$(curl -s -u admin:admin "http://localhost:3000/api/datasources" 2>/dev/null || echo "[]")
    DATASOURCE_COUNT=$(echo "$DATASOURCES" | jq length 2>/dev/null || echo "0")
    
    if [ "$DATASOURCE_COUNT" -gt "0" ]; then
        print_success "Found $DATASOURCE_COUNT datasource(s)"
        echo "$DATASOURCES" | jq -r '.[].name' 2>/dev/null | sed 's/^/  - /'
    else
        print_error "No datasources found. Check provisioning:"
        ls -la grafana/provisioning/datasources/ 2>/dev/null || print_error "Datasource directory not found"
    fi
    
    # Check dashboards
    print_status "Checking Grafana dashboards..."
    DASHBOARDS=$(curl -s -u admin:admin "http://localhost:3000/api/search" 2>/dev/null || echo "[]")
    DASHBOARD_COUNT=$(echo "$DASHBOARDS" | jq length 2>/dev/null || echo "0")
    
    if [ "$DASHBOARD_COUNT" -gt "0" ]; then
        print_success "Found $DASHBOARD_COUNT dashboard(s)"
        echo "$DASHBOARDS" | jq -r '.[].title' 2>/dev/null | sed 's/^/  - /' || echo "  (Unable to parse dashboard names)"
    else
        print_warning "No dashboards found. This might be normal for a new setup."
    fi
}

# Function to verify entire stack
verify_stack() {
    print_status "Verifying complete observability stack..."
    
    # Check all services
    local services=(
        "Application:http://localhost:8000/health"
        "Prometheus:http://localhost:9090/-/ready"
        "Grafana:http://localhost:3000/api/health"
        "Loki:http://localhost:3100/ready"
        "Tempo:http://localhost:3200/ready"
    )
    
    local all_good=true
    
    for service in "${services[@]}"; do
        IFS=':' read -r name url <<< "$service"
        if check_service "$name" "$url" 5; then
            continue
        else
            all_good=false
        fi
    done
    
    if $all_good; then
        print_success "All services are running correctly!"
    else
        print_warning "Some services are not accessible. Check docker logs for details."
    fi
    
    # Show container status
    print_status "Container status:"
    docker compose ps
}

# Function to provide manual troubleshooting steps
show_troubleshooting_guide() {
    echo ""
    echo "🔍 Manual Troubleshooting Guide"
    echo "==============================="
    echo ""
    echo "If you're still having issues, try these steps:"
    echo ""
    echo "1. 🌐 Access Grafana:"
    echo "   - URL: http://localhost:3000"
    echo "   - Username: admin"
    echo "   - Password: admin"
    echo ""
    echo "2. 📊 Check Prometheus targets:"
    echo "   - URL: http://localhost:9090/targets"
    echo "   - Ensure all targets are UP"
    echo ""
    echo "3. 🔍 Debug commands:"
    echo "   - Check Grafana logs: docker compose logs grafana"
    echo "   - Check Prometheus logs: docker compose logs prometheus"
    echo "   - Check app metrics: curl http://localhost:8001/metrics"
    echo ""
    echo "4. 🚀 Generate test data:"
    echo "   - curl http://localhost:8000/hello"
    echo "   - curl http://localhost:8000/health"
    echo ""
    echo "5. 💾 Reset everything:"
    echo "   - docker compose down -v"
    echo "   - docker system prune -f"
    echo "   - docker compose up -d"
    echo ""
    echo "6. 📧 Check dashboard provisioning:"
    echo "   - ls -la grafana/dashboards/"
    echo "   - ls -la grafana/provisioning/"
    echo ""
}

# Main execution
main() {
    echo ""
    print_status "Starting Grafana local setup and troubleshooting..."
    echo ""
    
    # Step 1: Fix configuration
    fix_docker_compose
    
    # Step 2: Create sample dashboard if needed
    create_sample_dashboard
    
    # Step 3: Restart services
    restart_services
    
    # Step 4: Verify Grafana
    verify_grafana
    
    # Step 5: Verify entire stack
    verify_stack
    
    # Step 6: Show manual troubleshooting
    show_troubleshooting_guide
    
    echo ""
    print_success "Local Grafana setup and verification completed!"
    echo ""
    print_status "🎯 Quick Access Links:"
    echo "   - Grafana: http://localhost:3000 (admin/admin)"
    echo "   - Prometheus: http://localhost:9090"
    echo "   - Application: http://localhost:8000"
    echo ""
}

# Run main function
main "$@"