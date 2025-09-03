FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY ./app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY ./app .

# Create log directory
RUN mkdir -p /var/log/app

# Expose ports (8000 for app, 8001 for metrics)
EXPOSE 8000 8001

# Run the application from the app directory
WORKDIR /app
CMD ["python", "-m", "uvicorn", "src.main:app", "--host", "0.0.0.0", "--port", "8000"]
