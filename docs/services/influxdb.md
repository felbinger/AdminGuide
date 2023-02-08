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

Unfortunately you need to copy some file out of the container before you can use influxdb:
```shell
sudo mkdir -p /srv/main/influxdb

sudo docker-compose up -d influxdb

sudo docker cp influxdb-influxdb-1:/var/lib/influxdb \
  /srv/main/influxdb/lib

sudo docker cp influxdb-influxdb-1:/etc/influxdb/influxdb.conf \
  /srv/main/influxdb/influxdb.conf
```

Afterwards you can remove the comments in front of the volumes and start up the container.
