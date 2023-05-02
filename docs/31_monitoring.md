# Monitoring

!!! info ""
    Work in progress - not finished yet!

Als Monitoring verwenden wir den Prometheus Stack (
  [Prometheus](https://github.com/prometheus/prometheus)
  + [Alertmanager](https://github.com/prometheus/alertmanager) 
  + [Pushgateway](https://github.com/prometheus/pushgateway)) mit 
  [Grafana](https://grafana.com/) zur Visualisierung.

Zum Erfassen der Sensordaten verwenden wir neben 
[node_exporter](https://github.com/prometheus/node_exporter) (generelle Hoststatistiken), 
[blackbox_exporter](https://github.com/prometheus/blackbox_exporter) (ICMP & HTTP Tests) und
[cAdvisor](https://github.com/google/cadvisor) (für Docker) auch Anwendungsspezifische Prometheus 
Exporter (nginx, mysql, postgresql, ssh, gitlab, grafana, ...). Viele von diesen sind in 
[dieser Liste](https://prometheus.io/docs/instrumenting/exporters/#third-party-exporters) zu finden.

```yaml
version: '3.9'

services:
  grafana:
    image: grafana/grafana
    restart: always
    volumes:
      - "/srv/monitoring/grafana/lib:/var/lib/grafana"
      - "/srv/monitoring/grafana/etc:/etc/grafana"
    ports:
      - "[::1]:8000:3000"

  prometheus:
    image: quay.io/prometheus/prometheus
    restart: always
    volumes:
      - "/srv/monitoring/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml"
      - "/srv/monitoring/prometheus/data:/prometheus"
    ports:
      - "[::1]:9090:9090"

  alertmanager:
    image: quay.io/prometheus/alertmanager
    restart: always
    ports:
      - "[::1]:9093:9093"

  pushgateway:
    image: quay.io/prometheus/pushgateway
    restart: always
    ports:
      - "[::1]:9091:9091"

  node_exporter:
    image: quay.io/prometheus/node-exporter
    restart: always
    volumes:
      - "/proc:/host/proc:ro"
      - "/sys:/host/sys:ro"
      - "/:/rootfs:ro"
    command:
      - "--path.procfs=/host/proc"
      - "--path.sysfs=/host/sys"
      - "--path.rootfs=/rootfs"
      - "--collector.filesystem.ignored-mount-points='^(/rootfs|/host|)/(sys|proc|dev|host|etc)($$|/)'"
      - "--collector.filesystem.ignored-fs-types='^(sys|proc|auto|cgroup|devpts|ns|au|fuse\.lxc|mqueue)(fs|)$$'"

  blackbox_exporter:
    image: quay.io/prometheus/blackbox-exporter
    restart: always
    command: "--config.file=/config/config.yaml"
    volumes:
      - "/srv/monitoring/blackbox_exporter/:/config/"

  cadvisor:
    image: gcr.io/cadvisor/cadvisor
    restart: always
    #privileged: true
    #devices:
    #  - "/dev/kmsg:/dev/kmsg"
    volumes:
      - "/:/rootfs:ro"
      - "/var/run:/var/run:ro"
      - "/sys:/sys:ro"
      - "/var/lib/docker:/var/lib/docker:ro"
      - "/cgroup:/cgroup:ro"
```

```yaml
# /srv/monitoring/prometheus/prometheus.yaml
global:
  scrape_interval: 30s
  evaluation_interval: 30s

alerting:
  alertmanagers:
  - scheme: http
    static_configs:
    - targets: 
      - 'alertmanager:9093'

scrape_configs:
  - job_name: 'prometheus'
    static_configs:
    - targets: ['localhost:9090']

  - job_name: 'blackbox_exporter_http'
    metrics_path: '/probe'
    params: 
      module: [http_2xx]
    static_configs:
      - targets:
        - https://www.google.de
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115

  - job_name: 'blackbox_exporter_icmp'
    metrics_path: '/probe'
    params: 
      module: [icmp]
    static_configs:
      - targets:
        - google.com
    relabel_configs:
      - source_labels: [__address__]
        target_label: __param_target
      - source_labels: [__param_target]
        target_label: instance
      - target_label: __address__
        replacement: blackbox-exporter:9115

  - job_name: 'blackbox_exporter'
    static_configs:
      - targets:
        - blackbox-exporter:9115

  - job_name: 'node_exporter'
    static_configs:
      - targets:
        - node_exporter:9100

  - job_name: 'cadvisor'
    static_configs:
      - targets:
        - "cadvisor:8080"

  - job_name: pushgateway
    honor_labels: true
    static_configs:
      - targets: ['pushgateway:9091']
```

```yaml
# /srv/monitoring/blackbox_exporter/config.yaml
modules:
  http_2xx:
    prober: http
    http:
      preferred_ip_protocol: "ip4"  # defaults to "ip6"
  icmp:
    prober: icmp
    icmp:
      preferred_ip_protocol: "ip4"  # defaults to "ip6"
```
