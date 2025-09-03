@echo off
echo 🚀 Starting Pulse-Check Monitoring Stack for Local Development
echo =============================================================

REM Check if Docker is available
docker --version >nul 2>&1
if %errorlevel% neq 0 (
    echo ❌ Docker is not installed or not in PATH
    exit /b 1
)

REM Stop any existing containers
echo 🛑 Stopping existing containers...
docker compose down -v 2>nul

REM Set environment variables for local development
set BRANCH=local-dev
set APP_LOG_PATH=/var/log/app/app.log

echo 🔧 Configuration:
echo   - Branch: %BRANCH%
echo   - Environment: Local Development

REM Start all services
echo 🏗️ Starting monitoring stack...
docker compose up -d

echo ⏳ Waiting for services to initialize...
echo    This may take 30-60 seconds for all services to be ready...

REM Wait for services to start
timeout /t 15 /nobreak >nul

echo.
echo 🔍 Checking service health...

REM Function to check service health (simplified for batch)
echo    Application: 
curl -s -f http://localhost:8000/health >nul 2>&1 && echo ✅ Ready || echo ❌ Not ready

echo    Prometheus: 
curl -s -f http://localhost:9090/-/ready >nul 2>&1 && echo ✅ Ready || echo ❌ Not ready

echo    Grafana: 
curl -s -f http://localhost:3000/api/health >nul 2>&1 && echo ✅ Ready || echo ❌ Not ready

echo    Loki: 
curl -s -f http://localhost:3100/ready >nul 2>&1 && echo ✅ Ready || echo ❌ Not ready

REM Generate some test data
echo.
echo 🧪 Generating test data...
for /L %%i in (1,1,10) do (
    start /B curl -s http://localhost:8000/hello >nul 2>&1
    start /B curl -s http://localhost:8000/health >nul 2>&1
)

timeout /t 2 /nobreak >nul
echo    Generated initial test traffic

REM Display access information
echo.
echo 🎉 Monitoring stack is ready!
echo.
echo 📍 Access Points:
echo    🎯 Grafana Dashboard: http://localhost:3000
echo       └── Username: admin
echo       └── Password: admin
echo.
echo    📊 Prometheus Metrics: http://localhost:9090
echo    📋 Application Logs: http://localhost:3100
echo    🔍 Trace Analysis: http://localhost:3200
echo    🏥 App Health Check: http://localhost:8000/health
echo.
echo 💡 Troubleshooting:
echo    • If dashboards are empty, wait a few minutes for data collection
echo    • Generate more test data: curl http://localhost:8000/hello
echo    • Check container status: docker compose ps
echo.
echo 🛑 To stop: docker compose down
echo.

pause