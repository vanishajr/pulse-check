FROM grafana/grafana:latest

# Copy provisioning configs and dashboards
COPY ./grafana/provisioning /etc/grafana/provisioning
COPY ./grafana/dashboards /var/lib/grafana/dashboards

EXPOSE 3000
