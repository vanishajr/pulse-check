FROM python:3.11-slim

WORKDIR /app

# Install dependencies
COPY ./app/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy source code
COPY ./app .

EXPOSE 8080

CMD ["python", "src/main.py"]
