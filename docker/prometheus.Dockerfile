FROM prom/prometheus:latest

# Copy your scrape config
COPY ./observability/prometheus.yml /etc/prometheus/prometheus.yml

EXPOSE 9090
