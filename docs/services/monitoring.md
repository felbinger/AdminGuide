## Resource Monitoring
I'm using [Telegraf](https://www.influxdata.com/time-series-platform/telegraf/), [InfluxDB](https://www.influxdata.com/products/influxdb-overview/) and [Grafana](https://grafana.com/) as frontend to monitor my server resources.

![Grafana Dashboard](../img/services/grafana_dashboard.png?raw=true)
```yaml
  # shell: docker-compose exec influxdb influx -precision rfc3339
  influxdb:
    image: influxdb
    restart: always
    #volumes:
    #  - /srv/main/influxdb/lib:/var/lib/influxdb
    #  - /srv/main/influxdb/influxdb.conf:/etc/influxdb/influxdb.conf
    environment:
      INFLUXDB_GRAPHITE_ENABLED: 1
    networks:
      monitoring:
        ipv4_address: 192.168.2.254

  grafana:
    image: grafana/grafana
    restart: always
    depends_on:
      - influxdb
    #volumes:
    #  - /srv/main/grafana/lib:/var/lib/grafana
    #  - /srv/main/grafana/etc:/etc/grafana
    #  - /srv/main/grafana/log:/var/log/grafana
    environment:
      VIRTUAL_HOST: monitoring.domain.tld:3000
      LETSENCRYPT_HOST: monitoring.domain.tld
    networks:
      - monitoring
      - proxy
```

Unfortunately you need to copy the three volumes out of grafana before starting it up:
```bash
mkdir -p /srv/main/{grafana,influxdb}
# copy data directory
sudo docker cp main_grafana_1:/var/lib/grafana \
  /srv/main/grafana/lib
# copy config directory
sudo docker cp main_grafana_1:/etc/grafana \
  /srv/main/grafana/etc
# copy log directory
sudo docker cp main_grafana_1:/var/log/grafana \
  /srv/main/grafana/log
# adjust permissions
sudo chown -R 472:472 /srv/main/grafana/

# influxdb
sudo docker cp main_influxdb_1:/var/lib/influxdb \
  /srv/main/influxdb/lib
sudo docker cp main_influxdb_1:/etc/influxdb/influxdb.conf \
  /srv/main/influxdb/influxdb.conf
```

Afterwards you can remove the comments in front of the volumes and start up the container. The default login for grafana is `admin`:`admin`.

## Telegraf Collecting Agent
```bash
$ sudo apt install apt-transport-https wget gnupg
$ wget -qO- https://repos.influxdata.com/influxdb.key | sudo apt-key add -
$ echo "deb https://repos.influxdata.com/debian buster stable" | sudo tee -a /etc/apt/sources.list.d/influxdb.list
$ sudo apt update
$ sudo apt install telegraf
```

**Command are below...**
In terms of configuration you first have to disable the influxdb output in the `telegraf.conf`. We are not going to use it, because it might be overwritten on telegraf updates. Just search for `[[outputs.influxdb]]` and put a `#` in front of it to mark it as a comment. The telegraf daemon will try to send data to the default url which is `localhost:8086`. In our case, with influxdb inside the docker helper network, `monitoring` we will reach the influxdb on the ip address `192.168.2.254` via a network bridge (check `ip route` for more information).

```bash
...
###############################################################################
#                            OUTPUT PLUGINS                                   #
###############################################################################


# Configuration for sending metrics to InfluxDB
#[[outputs.influxdb]]                                                         # <-- there
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
  urls = ["http://192.168.2.254:8086"]                                             # <-- there
...
```

```bash
# configure telegraf (hostname.conf should match your hostname)
sudo cp /etc/telegraf/telegraf.{conf,d/hostname.conf}
sudo nano /etc/telegraf/telegraf.{conf,d/hostname.conf}
sudo systemctl restart telegraf
```

### Monitoring docker instances from the host
You can monitor your docker instances using the on the host running telegraf instance if you assign these docker containers a static ip address, like in influxdb:
```yaml
...
networks:
  database:
    ip_address: 192.168.1.254
...
```
Afterwards you can go to the input section in your telegraf configuration (`/etc/telegraf/telegraf.d/{hostname}.conf`) and add the new "input's".

### More Resources
* [InfluxDB Authentication](https://docs.influxdata.com/influxdb/v1.7/administration/authentication_and_authorization/)
