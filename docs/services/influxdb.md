# InfluxDB

```yaml
version: '3.9'

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

Da der Container die, in den Volumes liegenden Daten, 
nicht kopiert müssen wir das zuvor manuell erledigen:
```sh
sudo mkdir -p /srv/influxdb

sudo docker compose up -d influxdb

sudo docker cp influxdb-influxdb-1:/var/lib/influxdb \
  /srv/influxdb/lib

sudo docker cp influxdb-influxdb-1:/etc/influxdb/influxdb.conf \
  /srv/influxdb/influxdb.conf
```

Entfernen Sie anschließend die Kommantare vor den 
Volumes in der Containerdefinition (`docker-compose.yml`).
