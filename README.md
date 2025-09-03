# 🚀 PR-based Ephemeral Monitoring with Grafana & OpenTelemetry

A comprehensive CI/CD solution that automatically monitors and analyzes the performance impact of every pull request using OpenTelemetry, Prometheus, Loki, and Grafana.

## 🎯 Project Overview

Whenever a pull request is created, this system automatically:

1. **Detects the branch** and spins up a temporary monitoring environment
2. **Runs the application** with full OpenTelemetry instrumentation
3. **Collects metrics, logs, and traces** via Prometheus and Loki
4. **Generates performance reports** and Grafana dashboard snapshots
5. **Posts analysis back to the PR** with actionable insights
6. **Tears down the environment** to save resources

### 🎪 Live Demo

- **Grafana**: http://localhost:3000 (admin/admin)
- **Prometheus**: http://localhost:9090
- **Application**: http://localhost:8000

## 👥 Team Responsibilities

### ✅ Person 1: CI/CD Pipeline Master
**Status: COMPLETE** 🎉
- GitHub Actions workflows for automated PR analysis
- Branch detection and environment lifecycle management
- Artifact collection and cleanup automation

### ✅ Person 2: Environment & Docker Engineer  
**Status: COMPLETE** 🎉
- Docker Compose orchestration for observability stack
- Service networking and resource management
- Container health checks and dependency management

### ✅ Person 3: Observability & Metrics Person
**Status: COMPLETE** 🎉
- OpenTelemetry integration with metrics, logs, and traces
- Prometheus scrape configuration and Loki log collection
- Branch-specific metric labeling for dashboard filtering

### ✅ Person 4: Visualization & Reporting
**Status: COMPLETE** 🎉
- Grafana dashboard creation and provisioning
- Automated snapshot generation with retention policies
- Comprehensive PR reporting with performance analysis

## 🚀 Quick Start

### Prerequisites
- Docker and Docker Compose
- Git
- GitHub repository with Actions enabled

### 1. Local Development
```bash
# Clone and start the stack
git clone <your-repo>
cd pulse-check

# Start monitoring stack
export BRANCH=$(git branch --show-current)
docker-compose up -d

# Wait for services (about 60 seconds)
# Access Grafana: http://localhost:3000 (admin/admin)
```

### 2. PR Monitoring (Automatic)
Just create a pull request! The system will:
- Automatically trigger performance analysis
- Generate comprehensive reports
- Post results as PR comments
- Create Grafana snapshots

### 3. Manual Analysis
```bash
# Generate reports manually
./scripts/generate_pr_report.sh 123 feature-branch markdown

# Create Grafana snapshots
./scripts/snapshot_grafana.sh feature-branch 123

# Post PR comments
./scripts/post_pr_comment.sh 123 feature-branch
```

## 📊 Available Workflows

### 1. **Standard PR Monitoring** (`pr-monitor.yml`)
- **Trigger**: Automatic on PR creation/updates
- **Features**: Basic performance testing, Grafana snapshots, PR comments
- **Duration**: ~5-10 minutes

### 2. **Comprehensive Analysis** (`complete-pr-analysis.yml`)  
- **Trigger**: Manual or `/analyze` PR comment
- **Features**: Detailed metrics, multiple report formats, extended snapshots
- **Duration**: ~10-15 minutes

### 3. **Load Testing** (`pr-load-test.yml`)
- **Trigger**: Manual or `/load-test` PR comment
- **Features**: K6 load testing, stress analysis, performance thresholds
- **Duration**: ~15-20 minutes
- **Usage**: `/load-test duration=300 users=50`

### 4. **Performance Comparison** (`pr-performance-compare.yml`)
- **Trigger**: Manual workflow dispatch
- **Features**: Branch vs branch performance comparison
- **Duration**: ~20-25 minutes

## 📈 Dashboard Features

### **PR Overview Dashboard**
- Real-time request rates and response times
- Error rate monitoring with alerting thresholds
- Branch-specific metric filtering
- Log correlation and trace analysis

### **Latency & Error Analysis**
- Detailed percentile analysis (P50, P95, P99)
- HTTP status code distribution
- Endpoint-specific performance breakdown
- Error pattern identification

## 🎯 Performance Analysis

### **Automated Grading System**
- 🟢 **Excellent**: P95 < 0.5s, Error Rate < 0.1%
- 🟢 **Good**: P95 < 1.0s, Error Rate < 1%  
- 🟡 **Fair**: P95 < 2.0s, Error Rate < 5%
- 🔴 **Poor**: Above thresholds

### **Generated Reports**
- **Markdown**: PR comments and GitHub integration
- **HTML**: Rich visual reports with charts
- **JSON**: Machine-readable data for integrations

### **Grafana Snapshots**
- **Standard**: 24-hour retention for quick review
- **Detailed**: 14-day retention for comprehensive analysis
- **Load Test**: 7-day retention with extended metrics

## 🛠️ Configuration

### **Environment Variables**
```bash
# Application
BRANCH=feature-branch              # Git branch being tested
OTEL_EXPORTER_OTLP_ENDPOINT=tempo:4317
PROM_METRICS_PORT=8001

# Grafana
GRAFANA_URL=http://localhost:3000
GRAFANA_USER=admin
GRAFANA_PASSWORD=admin

# Prometheus  
PROMETHEUS_URL=http://localhost:9090
```

### **Custom Thresholds**
Edit performance thresholds in:
- `scripts/generate_pr_report.sh`
- Workflow files under `.github/workflows/`

## 📁 Project Structure

```
pulse-check/
├── .github/workflows/          # GitHub Actions workflows
│   ├── pr-monitor.yml         # Standard PR monitoring
│   ├── complete-pr-analysis.yml # Comprehensive analysis
│   ├── pr-load-test.yml       # Load testing
│   └── pr-performance-compare.yml # Performance comparison
├── app/                       # Application code
│   ├── src/main.py           # FastAPI app with OpenTelemetry
│   └── requirements.txt      # Python dependencies
├── grafana/                   # Grafana configuration
│   ├── dashboards/           # Dashboard definitions
│   └── provisioning/         # Datasource and dashboard configs
├── observability/            # Monitoring stack configs
│   ├── prometheus.yml        # Prometheus configuration
│   ├── loki-config.yaml     # Loki configuration
│   └── tempo-config.yaml    # Tempo configuration
├── scripts/                  # Utility scripts
│   ├── generate_pr_report.sh # Comprehensive report generation
│   ├── snapshot_grafana.sh   # Grafana snapshot creation
│   ├── post_pr_comment.sh    # PR comment posting
│   └── cleanup.sh           # Environment cleanup
└── docker-compose.yml        # Full observability stack
```

## 🔧 Troubleshooting

### **Common Issues**

1. **Services not starting**
   ```bash
   docker-compose ps
   docker-compose logs <service>
   ```

2. **Grafana dashboards not loading**
   ```bash
   # Check provisioning
   docker-compose logs grafana
   curl -u admin:admin http://localhost:3000/api/search
   ```

3. **No metrics appearing**
   ```bash
   # Check Prometheus targets
   curl http://localhost:9090/api/v1/targets
   
   # Check app metrics endpoint
   curl http://localhost:8001/metrics
   ```

4. **Cleanup stuck processes**
   ```bash
   ./scripts/cleanup.sh --force
   ```

### **Performance Tuning**

- **Memory**: Increase Docker memory allocation to 4GB+
- **CPU**: Ensure 2+ CPU cores available
- **Storage**: Monitor disk usage during long-running tests

## 🚀 Advanced Usage

### **Custom Load Tests**
```javascript
// Example K6 script
import http from 'k6/http';

export const options = {
  vus: 20,
  duration: '2m',
};

export default function() {
  http.get('http://localhost:8000/hello');
}
```

### **Custom Dashboards**
```json
{
  "title": "Custom PR Dashboard",
  "panels": [
    {
      "title": "Custom Metric",
      "targets": [{
        "expr": "your_custom_metric{branch=\"$branch\"}"
      }]
    }
  ]
}
```

### **Integration with External Services**
```bash
# Post to Slack
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"PR Performance Report: '$SNAPSHOT_URL'"}' \
  YOUR_SLACK_WEBHOOK

# Upload to S3
aws s3 cp pr-reports/ s3://your-bucket/pr-reports/ --recursive
```

## 🏆 Success Metrics

### **Developer Experience**
- ⚡ **Fast Feedback**: Results in <10 minutes
- 📊 **Rich Insights**: Visual dashboards and detailed reports
- 🔄 **Automated**: Zero manual intervention required
- 📈 **Actionable**: Clear recommendations for optimization

### **System Performance**
- 🎯 **Early Detection**: Catch performance regressions before merge
- 📉 **Trend Analysis**: Track performance over time
- 🚨 **Alerting**: Automated threshold monitoring
- 🔍 **Root Cause**: Detailed trace and log correlation

## 🤝 Contributing

1. **Fork** the repository
2. **Create** a feature branch
3. **Test** with the monitoring stack
4. **Submit** a pull request (and watch the magic happen!)

## 📝 License

MIT License - see [LICENSE](LICENSE) file for details.

---

**🎉 Happy Monitoring!** This system gives you enterprise-grade performance insights without the enterprise complexity.

*Built with ❤️ using OpenTelemetry, Grafana, Prometheus, and GitHub Actions*