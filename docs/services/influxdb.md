# InfluxDB

InfluxDB ist eine Open-Source-Zeitreihendatenbank, die speziell für die Speicherung, Abfrage und Visualisierung von
Zeitreihendaten optimiert ist.

```yaml
services:
  # shell: docker-compose exec influxdb influx -precision rfc3339
  influxdb:
    image: influxdb
    restart: always
    environment:
      - "INFLUXDB_GRAPHITE_ENABLED=1"
    #volumes:
    #  - "/srv/influxdb/data:/var/lib/influxdb"
    #  - "/srv/influxdb/influxdb.conf:/etc/influxdb/influxdb.conf"
```

Bevor du InfluxDB verwenden kannst, musst du ein paar Dateien aus dem Container kopieren:
```shell
sudo mkdir -p /srv/main/influxdb

sudo docker compose up -d influxdb

sudo docker cp influxdb-influxdb-1:/var/lib/influxdb \
  /srv/main/influxdb/lib

sudo docker cp influxdb-influxdb-1:/etc/influxdb/influxdb.conf \
  /srv/main/influxdb/influxdb.conf
```

Nachdem du die Dateien kopiert hast, kannst du die Kommentare von den Volumes entfernen und den Container starten.