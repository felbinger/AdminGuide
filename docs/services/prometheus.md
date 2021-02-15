A lot of applications ([checkout the list of applications](https://prometheus.io/docs/instrumenting/exporters/#software-exposing-prometheus-metrics)) have an endpoint which can be used to query metrics.  

If they aren't specificly made for prometheus you can [write an exporter](https://prometheus.io/docs/instrumenting/writing_exporters/)
to make them prometheus compatible (e.g. for [nextcloud](https://github.com/xperimental/nextcloud-exporter),
[jitsi](https://github.com/an2ic3/jitsi2prometheus)).

Simply add the prometheus service definition to the `docker-compose.yml`, in which the monitoring services are defined.
```yaml
  prometheus:
    image: prom/prometheus
    restart: always
    volumes:
      - '/srv/main/prometheus/prometheus.yml:/etc/prometheus/prometheus.yml'
      - 'prometheus-data:/prometheus'
    networks:
      - monitoring

# ...

volumes:
  prometheus-data:
```

The `prometheus.yml` contain a list of metrics endpoints, that should be queried:
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
