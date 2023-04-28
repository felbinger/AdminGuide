# Prometheus

Prometheus ist ein Open-Source-System für das Monitoring und die Alarmierung von IT-Systemen und -Diensten, das eine
flexible Abfragesprache und eine Vielzahl von Tools für die Visualisierung und Analyse von Daten bietet.


Es gibt viele Dienste ([Siehe die Liste der Dienste](https://prometheus.io/docs/instrumenting/exporters/#software-exposing-prometheus-metrics)),
wo man die Daten von einem Server auslesen kann.

Wenn der Dienst es nicht explizit für Prometheus bereitstellt, kann man einen [eigenen Exporter schreiben](https://prometheus.io/docs/instrumenting/writing_exporters/),
um dies Prometheus Kompatibel zu machen (z. B. for [nextcloud](https://github.com/xperimental/nextcloud-exporter),
[jitsi](https://github.com/an2ic3/jitsi2prometheus)).


Man kann einfach den prometheus service in die `docker-compose.yml` hinzufügen, in welche man den monitoring service definiert. 

```yaml
version: '3.9'

services:
  prometheus:
    image: prom/prometheus
    restart: always
    volumes:
      - '/srv/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml'
      - '/srv/prometheus/data:/prometheus'
```

Die `prometheus.yml` enthält eine Liste von Datenendpunkten, welche aufgezeichnet werden sollen
```yaml
global:
  scrape_interval:     15s
  evaluation_interval: 15s

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
    - targets: ['localhost:9090']

  # query jitsi statistics
  - job_name: 'jitsi'
    static_configs:
      - targets: ['jitsi2prometheus:8080']

  # query traefik statistics
  - job_name: 'traefik'
    static_configs:
      - targets: ['traefik:8080']
```

In manchen Service-Setup Erklärungen findet man den "Metrics exportieren" abschnitt, aber dies gibt es nicht bei jedem
Service!
