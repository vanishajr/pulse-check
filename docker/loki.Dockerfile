FROM grafana/loki:latest

# Copy your Loki config
COPY ./observability/loki-config.yaml /etc/loki/local-config.yaml

EXPOSE 3100

CMD ["-config.file=/etc/loki/local-config.yaml"]
