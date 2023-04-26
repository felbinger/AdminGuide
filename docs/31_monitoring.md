# Monitoring

Als Monitoring verwenden wir den Prometheus Stack (Prometheus + Alertmanager + Pushgateway) mit Grafana zur Visualisierung.

```yaml
version: '3.9'

services:
  grafana:  # see grafana for setup instructions
    image: grafana/grafana
    restart: always
    volumes:
      - "/srv/monitoring/grafana/lib:/var/lib/grafana"
      - "/srv/monitoring/grafana/etc:/etc/grafana"
    ports:
      - "[::1]:8000:3000"

  prometheus:  # see prometheus for setup instructions
    image: prom/prometheus
    restart: always
    volumes:
      - "/srv/monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml"
      - "/srv/monitoring/prometheus/data:/prometheus"

  # TODO add pushgateway

  # TODO add alertmanager
```
