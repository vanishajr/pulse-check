# app/src/main.py
import os
import time
import logging
from logging.handlers import RotatingFileHandler

from fastapi import FastAPI, Request, Query
from typing import Optional
from prometheus_client import Counter, Histogram, start_http_server
from opentelemetry import trace
from opentelemetry.instrumentation.fastapi import FastAPIInstrumentor
from opentelemetry.instrumentation.requests import RequestsInstrumentor
from opentelemetry.sdk.resources import Resource
from opentelemetry.sdk.trace import TracerProvider
from opentelemetry.sdk.trace.export import BatchSpanProcessor
from opentelemetry.exporter.otlp.proto.grpc.trace_exporter import OTLPSpanExporter


BRANCH = os.getenv("GITHUB_HEAD_REF") or os.getenv("BRANCH") or "local-dev"
resource = Resource.create({"service.name": "pr-app", "branch": BRANCH})
tracer_provider = TracerProvider(resource=resource)
otlp_endpoint = os.getenv("OTEL_EXPORTER_OTLP_ENDPOINT", "tempo:4317")
otlp_exporter = OTLPSpanExporter(endpoint=otlp_endpoint, insecure=True)
tracer_provider.add_span_processor(BatchSpanProcessor(otlp_exporter))
trace.set_tracer_provider(tracer_provider)
tracer = trace.get_tracer(__name__)
REQUEST_COUNTER = Counter(
    "app_requests_total",
    "Total requests handled by the app",
    ["branch", "endpoint", "method", "status"]
)
REQUEST_LATENCY = Histogram(
    "app_request_duration_seconds",
    "Request latency seconds",
    ["branch", "endpoint", "method"]
)

PROM_METRICS_PORT = int(os.getenv("PROM_METRICS_PORT", "8001"))
start_http_server(PROM_METRICS_PORT)

# ---------- Logging (file) ----------
LOG_PATH = os.getenv("APP_LOG_PATH", "/var/log/app/app.log")
logger = logging.getLogger("pr-app")
logger.setLevel(logging.INFO)
handler = RotatingFileHandler(LOG_PATH, maxBytes=5*1024*1024, backupCount=2)
formatter = logging.Formatter(
    '{"timestamp":"%(asctime)s", "name":"%(name)s", "level":"%(levelname)s", "message":"%(message)s", "branch":"%(branch)s"}'
)
handler.setFormatter(formatter)
logger.addHandler(handler)

# ---------- FastAPI app ----------
app = FastAPI()

# Instrumentations
FastAPIInstrumentor.instrument_app(app)
RequestsInstrumentor().instrument()

@app.middleware("http")
async def metrics_middleware(request: Request, call_next):
    start = time.time()
    response = await call_next(request)
    duration = time.time() - start

    endpoint = request.url.path
    method = request.method
    status = str(response.status_code)

    # Prometheus metrics
    REQUEST_COUNTER.labels(BRANCH, endpoint, method, status).inc()
    REQUEST_LATENCY.labels(BRANCH, endpoint, method).observe(duration)

    # Structured logging (as JSON-ish string)
    logger.info(f"handled {method} {endpoint} -> {status} in {duration:.3f}s", extra={"branch": BRANCH})

    return response

@app.get("/hello")
def hello(delay: Optional[float] = Query(None, description="Artificial delay in seconds")):
    with tracer.start_as_current_span("hello-handler"):
        if delay and delay > 0:
            time.sleep(min(delay, 2.0))  # Cap delay at 2 seconds for safety
        return {"msg": f"Hello from branch {BRANCH}", "delay_applied": delay or 0}

@app.get("/health")
def health():
    return {"status": "ok", "branch": BRANCH}

if __name__ == "__main__":
    import uvicorn
    uvicorn.run("src.main:app", host="0.0.0.0", port=8000, reload=False)
