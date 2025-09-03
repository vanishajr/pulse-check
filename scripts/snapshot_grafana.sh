#!/bin/bash
# Script to create Grafana snapshots for PR monitoring
# Usage: ./snapshot_grafana.sh [branch_name] [pr_number]

set -e

# Configuration
GRAFANA_URL="${GRAFANA_URL:-http://localhost:3000}"
GRAFANA_USER="${GRAFANA_USER:-admin}"
GRAFANA_PASSWORD="${GRAFANA_PASSWORD:-admin}"

# Parameters
BRANCH="${1:-$(git branch --show-current 2>/dev/null || echo 'main')}"
PR_NUMBER="${2:-unknown}"

echo "Creating Grafana snapshot for branch: $BRANCH, PR: $PR_NUMBER"

# Function to check if Grafana is ready
check_grafana_ready() {
    local max_attempts=10
    local attempt=1
    
    echo "Checking if Grafana is ready..."
    
    while [ $attempt -le $max_attempts ]; do
        if curl -f -s -u "$GRAFANA_USER:$GRAFANA_PASSWORD" "$GRAFANA_URL/api/org" >/dev/null 2>&1; then
            echo "Grafana is ready (attempt $attempt/$max_attempts)"
            return 0
        fi
        
        echo "Grafana not ready, waiting... (attempt $attempt/$max_attempts)"
        sleep 3
        attempt=$((attempt + 1))
    done
    
    echo "Grafana not ready after $max_attempts attempts"
    return 1
}

# Function to create snapshot with error handling
create_snapshot() {
    local snapshot_name="$1"
    local dashboard_json="$2"
    
    echo "Creating snapshot: $snapshot_name"
    
    # Create snapshot payload
    local payload=$(cat << EOF
{
    "name": "$snapshot_name",
    "expires": 86400,
    "external": false,
    $dashboard_json
}
EOF
)
    
    # Try to create snapshot with retries
    local max_attempts=3
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        echo "Attempt $attempt/$max_attempts to create snapshot..."
        
        local response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
            -X POST "$GRAFANA_URL/api/snapshots" \
            -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
            -H "Content-Type: application/json" \
            -d "$payload" 2>/dev/null)
        
        local body=$(echo "$response" | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')
        local status=$(echo "$response" | grep -o -E "[0-9]{3}$")
        
        if [ "$status" = "200" ]; then
            local snapshot_key=$(echo "$body" | jq -r '.key // empty' 2>/dev/null)
            local delete_key=$(echo "$body" | jq -r '.deleteKey // empty' 2>/dev/null)
            
            if [ -n "$snapshot_key" ] && [ "$snapshot_key" != "null" ]; then
                local snapshot_url="$GRAFANA_URL/dashboard/snapshot/$snapshot_key"
                echo "Snapshot created successfully!"
                echo "Snapshot URL: $snapshot_url"
                echo "Snapshot Key: $snapshot_key"
                echo "Delete Key: $delete_key"
                echo "Expires in 24 hours"
                
                # Output for GitHub Actions
                if [ -n "$GITHUB_ENV" ]; then
                    echo "SNAPSHOT_URL=$snapshot_url" >> "$GITHUB_ENV"
                    echo "SNAPSHOT_KEY=$snapshot_key" >> "$GITHUB_ENV"
                    echo "DELETE_KEY=$delete_key" >> "$GITHUB_ENV"
                    echo "HAS_SNAPSHOT=true" >> "$GITHUB_ENV"
                fi
                
                # Save to file for later reference
                echo "$snapshot_url" > snapshot_url.txt
                echo "URL saved to snapshot_url.txt"
                return 0
            fi
        fi
        
        echo "Snapshot creation failed (HTTP $status): $body"
        attempt=$((attempt + 1))
        
        if [ $attempt -le $max_attempts ]; then
            echo "Retrying in 5 seconds..."
            sleep 5
        fi
    done
    
    return 1
}

# Function to create simple fallback snapshot
create_simple_snapshot() {
    echo "Trying simplified snapshot creation..."
    
    local simple_payload=$(cat << 'EOF'
{
    "name": "Simple PR Snapshot",
    "expires": 3600,
    "external": false,
    "dashboard": {
        "title": "Simple Dashboard",
        "panels": []
    }
}
EOF
)
    
    local response=$(curl -s -w "HTTPSTATUS:%{http_code}" \
        -X POST "$GRAFANA_URL/api/snapshots" \
        -u "$GRAFANA_USER:$GRAFANA_PASSWORD" \
        -H "Content-Type: application/json" \
        -d "$simple_payload" 2>/dev/null)
    
    local body=$(echo "$response" | sed -E 's/HTTPSTATUS\:[0-9]{3}$//')
    local status=$(echo "$response" | grep -o -E "[0-9]{3}$")
    
    if [ "$status" = "200" ]; then
        local snapshot_key=$(echo "$body" | jq -r '.key // empty' 2>/dev/null)
        
        if [ -n "$snapshot_key" ] && [ "$snapshot_key" != "null" ]; then
            local snapshot_url="$GRAFANA_URL/dashboard/snapshot/$snapshot_key"
            echo "Simple snapshot created: $snapshot_url"
            
            if [ -n "$GITHUB_ENV" ]; then
                echo "SNAPSHOT_URL=$snapshot_url" >> "$GITHUB_ENV"
                echo "HAS_SNAPSHOT=true" >> "$GITHUB_ENV"
            fi
            
            echo "$snapshot_url" > snapshot_url.txt
            return 0
        fi
    fi
    
    echo "Simple snapshot creation also failed (HTTP $status): $body"
    return 1
}

# Main execution
main() {
    # Check if Grafana is accessible
    if ! check_grafana_ready; then
        echo "Cannot create snapshot - Grafana is not accessible"
        if [ -n "$GITHUB_ENV" ]; then
            echo "HAS_SNAPSHOT=false" >> "$GITHUB_ENV"
            echo "SNAPSHOT_ERROR=grafana_not_ready" >> "$GITHUB_ENV"
        fi
        exit 1
    fi
    
    # Create dashboard JSON for the snapshot
    local dashboard_json=$(cat << EOF
"dashboard": {
    "title": "PR $PR_NUMBER - $BRANCH Performance",
    "tags": ["pr-$PR_NUMBER", "$BRANCH"],
    "time": {
        "from": "now-10m",
        "to": "now"
    },
    "refresh": "5s",
    "panels": [
        {
            "title": "Request Rate",
            "type": "stat",
            "targets": [{
                "expr": "sum(rate(app_requests_total{branch=\\"$BRANCH\\"}[1m]))",
                "refId": "A"
            }],
            "gridPos": {"h": 8, "w": 6, "x": 0, "y": 0}
        },
        {
            "title": "95th Percentile Latency",
            "type": "stat",
            "targets": [{
                "expr": "histogram_quantile(0.95, sum(rate(app_request_duration_seconds_bucket{branch=\\"$BRANCH\\"}[5m])) by (le))",
                "refId": "A"
            }],
            "gridPos": {"h": 8, "w": 6, "x": 6, "y": 0}
        },
        {
            "title": "Error Rate",
            "type": "stat",
            "targets": [{
                "expr": "sum(rate(app_requests_total{branch=\\"$BRANCH\\",status=~\\"4..|5..\\"}[5m])) / sum(rate(app_requests_total{branch=\\"$BRANCH\\"}[5m])) * 100",
                "refId": "A"
            }],
            "gridPos": {"h": 8, "w": 6, "x": 12, "y": 0}
        },
        {
            "title": "Total Requests",
            "type": "stat",
            "targets": [{
                "expr": "sum(app_requests_total{branch=\\"$BRANCH\\"})",
                "refId": "A"
            }],
            "gridPos": {"h": 8, "w": 6, "x": 18, "y": 0}
        }
    ]
}
EOF
)
    
    # Try to create the detailed snapshot
    local snapshot_name="PR-$PR_NUMBER Snapshot ($BRANCH)"
    
    if create_snapshot "$snapshot_name" "$dashboard_json"; then
        echo "Detailed snapshot creation completed successfully!"
        exit 0
    fi
    
    echo "Detailed snapshot failed, trying simple version..."
    
    # Fallback to simple snapshot
    if create_simple_snapshot; then
        echo "Simple snapshot creation completed successfully!"
        exit 0
    fi
    
    # Both methods failed
    echo "All snapshot creation methods failed"
    echo "The monitoring system will continue to work without snapshots"
    
    if [ -n "$GITHUB_ENV" ]; then
        echo "HAS_SNAPSHOT=false" >> "$GITHUB_ENV"
        echo "SNAPSHOT_ERROR=creation_failed" >> "$GITHUB_ENV"
    fi
    
    # Don't exit with error - snapshots are nice-to-have, not critical
    exit 0
}

# Run main function
main "$@"