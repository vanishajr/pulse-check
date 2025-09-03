FROM grafana/tempo:latest

# Copy Tempo config
COPY ./observability/tempo-config.yaml /etc/tempo/tempo.yaml

EXPOSE 3200

CMD ["-config.file=/etc/tempo/tempo.yaml"]