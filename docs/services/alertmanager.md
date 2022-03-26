# Alertmanager

!!! warning ""
	This Admin Guide is being rewritten at the moment!



Sometimes monitoring is not enough and you want to be notified
about state changes in your system.
In a prometheus based monitoring infrastructure, alertmanager can handle this job.
In this example, we use msteams as the endpoint for notifications.

> [Checkout the admin-guide to setup prometheus](prometheus.md)

---
Add services to your monitoring `docker-compose.yaml`
```yaml
version: '3'

volumes:
  alertmanager:

services:
  alertmanager:
    image: quay.io/prometheus/alertmanager
    restart: always
    volumes:
      - ./alertmanager.yaml:/alertmanager.yaml:ro
    command:
      - --config.file=/alertmanager.yaml
#      - --web.external-url=your-domain
#    networks:
#      - monitoring
    ports:
      - 9093:9093

  msteams_receiver:
    image: quay.io/prometheusmsteams/prometheus-msteams
    restart: always
    environment:
      - TEAMS_INCOMING_WEBHOOK_URL="your-teams-webhook"
      - TEAMS_REQUEST_URI=alertmanager
#    networks:
#      - monitoring
```

---
Add your alerts directory to your prometheus service in the `docker-compose.yaml`

> You can find suggestions for alerts on [Awesome Prometheus alerts](https://awesome-prometheus-alerts.grep.to)

```yaml
version: '3'

services:
  prometheus:
    ...
    volumes:
      - ./alerts:/alerts:ro
```

---
Register the alertmanager service, alerts and additional configs in your `prometheus.yaml`
```yaml
global:
  scrape_interval: 30s
  evaluation_interval: 1m

rule_files:
  - '/alerts/*.yaml'

alerting:
  alertmanagers:
    - static_configs:
      - targets: ['alertmanager:9093']
```

---
Finally setup your `alertmanager.yaml`
```yaml
route:
  group_by: ['alertname', 'instance', 'job']
  repeat_interval: 15m
  receiver: 'teams'

receivers:
  - name: 'teams'
    webhook_configs:
      - send_resolved: true
        url: 'http://msteams_receiver_webhook'
```

---
## Resources

- [Alertmanager](https://prometheus.io/docs/alerting/latest/alertmanager/)
- [Awesome Prometheus alerts](https://awesome-prometheus-alerts.grep.to)
- [prometheus-msteams](https://github.com/prometheus-msteams/prometheus-msteams)
