## Reverse Proxy
* [jwilder/nginx-proxy](./services_nginx-proxy.md)
* [Traefik](./services_traefik.md)

## Databases
Next, let's set up some database management systems and administrative web portals for them:
```yml
  mariadb:
    image: mariadb
    restart: always
    environment:
      MYSQL_ROOT_PASSWORD: SECRET_PASSWORD
    volumes:
      - "/srv/main/mariadb/data:/var/lib/mysql"
      - "/srv/main/mariadb/transfer:/transfer"
    networks:
      - database

  mongodb:
    image: mongo
    restart: always
    environment:
      MONGO_INITDB_ROOT_USERNAME: root
      MONGO_INITDB_ROOT_PASSWORD: SECRET_PASSWORD
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "/srv/main/mongodb/transfer:/data/transfer"
      - "/srv/main/mongodb/data:/data/db"
    networks:
      - database

  postgresql:
    image: postgres
    restart: always
    environment:
      POSTGRES_PASSWORD: SECRET_PASSWORD
    volumes:
      - "/srv/main/postgres/transfer:/transfer"
      - "/srv/main/postgres/data:/var/lib/postgresql/data"
    networks:
      - database

  phpmyadmin:
    image: phpmyadmin/phpmyadmin
    restart: "no"
    depends_on:
      - mariadb
    environment:
      PMA_HOST: mariadb
      PMA_PORT: 3306
      PMA_ABSOLUTE_URI: https://phpmyadmin.domain.tld/
      VIRTUAL_HOST: phpmyadmin.domain.tld:80
      LETSENCRYPT_HOST: phpmyadmin.domain.tld
    volumes:
      - '/srv/main/phpmyadmin/php.ini:/usr/local/etc/php/php.ini'
    networks:
      - proxy
      - database

  pgadmin:
    image: dpage/pgadmin4
    restart: always
    environment:
      VIRTUAL_HOST: pgadmin.domain.tld:80
      LETSENCRYPT_HOST: pgadmin.domain.tld
      PGADMIN_DEFAULT_EMAIL: admin@domain.tld
      PGADMIN_DEFAULT_PASSWORD: SECRET_PASSWORD
    networks:
      - database
      - proxy
```

Don't forget to create your custom `/srv/main/phpmyadmin/php.ini` for phpmyadmin to increase the upload size of database imports. 
```
upload_max_filesize = 512M
post_max_size = 512M
memory_limit = 512M
max_execution_time = 300
```


Actually, let's add `redis` as key value store and `elasticsearch` too:
```yml
  redis:
    image: redis
    restart: always
    command: "redis-server --appendonly yes"
    volumes:
      - "/srv/main/redis:/data"
    networks:
      - database

  elasticsearch:
    image: elasticsearch:7.6.2
    restart: always
    environment:
      node.name: elasticsearch
      discovery.type: single-node
      ES_JAVA_OPTS: "-Xms512m -Xmx512m"
    volumes:
      - "/srv/main/elasticsearch:/usr/share/elasticsearch/data"
    networks:
      - database
```

I would suggest to stop administrative services over the night. They shouln't be online for longer then needed, you can do this using a cronjob:
```bash
# stop administrative services at 5 am during the week
00 05 * * 1-5 /usr/local/bin/docker-compose -f /home/admin/services/main/docker-compose.yml rm -fs phpmyadmin pgadmin 2>&1
```

### pgAdmin4 automatic login
* Make `/pgadmin4/servers.json` persistent, by adding a volume to this file
* Make the whole `storage` directory in `/var/lib/pgadmin/storage` persistent, and add this structure: `storage/admin_domain.tld/.pgpass`. Don't forget to adjust the permissions: `chown -R 5050:5050 /srv/main/pgadmin/`

## Portainer

![Portainer Dashboard](./img/services_portainer_dashboard.png?raw=true)
```yml
  portainer:
    image: portainer/portainer
    restart: always
    command: -H unix:///var/run/docker.sock
    environment:
      VIRTUAL_HOST: portainer.domain.tld:9000
      LETSENCRYPT_HOST: portainer.domain.tld
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock:ro
      - /srv/main/portainer:/data
    networks:
      - proxy
```

## Resource Monitoring
I'm using [Telegraf](https://www.influxdata.com/time-series-platform/telegraf/), [InfluxDB](https://www.influxdata.com/products/influxdb-overview/) and [Grafana](https://grafana.com/) as frontend to monitor my server resources.

![Grafana Dashboard](./img/services_grafana_dashboard.png?raw=true)
```yml
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
$ mkdir -p /srv/main/{grafana,influxdb}
# copy data directory
$ sudo docker cp main_grafana_1:/var/lib/grafana /srv/main/grafana/lib
# copy config directory
$ sudo docker cp main_grafana_1:/etc/grafana /srv/main/grafana/etc
# copy log directory
$ sudo docker cp main_grafana_1:/var/log/grafana /srv/main/grafana/log
# adjust permissions
$ sudo chown -R 472:472 /srv/main/grafana/

# influxdb
$ sudo docker cp main_influxdb_1:/var/lib/influxdb /srv/main/influxdb/lib
$ sudo docker cp main_influxdb_1:/etc/influxdb/influxdb.conf /srv/main/influxdb/influxdb.conf
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
$ sudo cp /etc/telegraf/telegraf.{conf,d/hostname.conf}
$ sudo nano /etc/telegraf/telegraf.{conf,d/hostname.conf}
$ sudo systemctl restart telegraf
```

### Monitoring docker instances from the host
You can monitor your docker instances using the on the host running telegraf instance if you assign these docker containers a static ip address, like in influxdb:
```yml
...
networks:
  database:
    ip_address: 192.168.1.254
...
```
Afterwards you can go to the input section in your telegraf configuration (`/etc/telegraf/telegraf.d/{hostname}.conf`) and add the new "input's".

### More Resources
* [InfluxDB Authentication](https://docs.influxdata.com/influxdb/v1.7/administration/authentication_and_authorization/)
