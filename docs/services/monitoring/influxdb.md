# InfluxDB

Checkout the official pages for [Telegraf](https://www.influxdata.com/time-series-platform/telegraf/) and
[InfluxDB](https://www.influxdata.com/products/influxdb-overview/)  

```yaml
  # shell: docker-compose exec influxdb influx -precision rfc3339
  influxdb:
    image: influxdb
    restart: always
    environment:
      - "INFLUXDB_GRAPHITE_ENABLED=1"
    #volumes:
    #  - "influx-data:/var/lib/influxdb"
    #  - "/srv/main/influxdb/influxdb.conf:/etc/influxdb/influxdb.conf"
    networks:
      monitoring:
        ipv4_address: 192.168.2.254

# ...

volumes:
  influx-data:
```

Unfortunately you need to copy some file out of the container before you can use influxdb:
```bash
sudo mkdir -p /srv/main/influxdb

sudo docker-compose up -d influxdb

sudo docker cp main_influxdb_1:/var/lib/influxdb \
  /srv/main/influxdb/lib

sudo docker cp main_influxdb_1:/etc/influxdb/influxdb.conf \
  /srv/main/influxdb/influxdb.conf
```

Afterwards you can remove the comments in front of the volumes and start up the container.

### Telegraf Collecting Agent on the host system
```bash
sudo apt install apt-transport-https wget gnupg
wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add -
echo "deb https://repos.influxdata.com/debian buster stable" | sudo tee -a /etc/apt/sources.list.d/influxdb.list
sudo apt update
sudo apt install telegraf
```

In terms of configuration you first have to disable the influxdb output in the `telegraf.conf`.
We are not going to use it, because it might be overwritten on telegraf updates.
Just search for `[[outputs.influxdb]]` and put a `#` in front of it to mark it as a comment.

The telegraf daemon will try to send data to the default url which is `localhost:8086`.
In our case, with influxdb inside the docker helper network, `monitoring` we will reach the influxdb on the ip address `192.168.2.254`.

```
# configure telegraf (hostname.conf should match your hostname)
sudo cp /etc/telegraf/telegraf.{conf,d/hostname.conf}
sudo vim /etc/telegraf/telegraf.{conf,d/hostname.conf}
```

```bash
...
###############################################################################
#                            OUTPUT PLUGINS                                   #
###############################################################################


# Configuration for sending metrics to InfluxDB
#[[outputs.influxdb]]                                                         # <-- comment this out
  ## The full HTTP or UDP URL for your InfluxDB instance.
  ##
  ## Multiple URLs can be specified for a single cluster, only ONE of the
  ## urls will be written to each interval.
  # urls = ["unix:///var/run/influxdb.sock"]
  # urls = ["udp://127.0.0.1:8089"]
  # urls = ["http://127.0.0.1:8086"]
...
```

Afterwards we are going to edit the copied telegraf configuration (`/etc/telegraf/telegraf.d/hostname.conf`). Just add the correct `urls` entry in the influxdb output area to get basic reporting which is enabled by default.

```bash
...
###############################################################################
#                            OUTPUT PLUGINS                                   #
###############################################################################


# Configuration for sending metrics to InfluxDB
[[outputs.influxdb]]
  ## The full HTTP or UDP URL for your InfluxDB instance.
  ##
  ## Multiple URLs can be specified for a single cluster, only ONE of the
  ## urls will be written to each interval.
  # urls = ["unix:///var/run/influxdb.sock"]
  # urls = ["udp://127.0.0.1:8089"]
  # urls = ["http://127.0.0.1:8086"]
  urls = ["http://192.168.2.254:8086"]                                             # <-- add this line
...
```

Finally you can restart the telegraf agent
```bash
sudo systemctl restart telegraf
```

You might also would like to enable [authentication](https://docs.influxdata.com/influxdb/v1.7/administration/authentication_and_authorization/)!
