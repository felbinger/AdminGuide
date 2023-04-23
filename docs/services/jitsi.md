# Jitsi

!!! info ""
	Due to the fact that the dockerized jitsi service is really painful, we suggest you use a separate virtual server for this.  
	We have setup scripts for [jitsi](https://github.com/secshellnet/docs/blob/main/scripts/jitsi.sh)
	and [jitsi-oidc](https://github.com/secshellnet/docs/blob/main/scripts/jitsi-oidc.sh).

Bei Problemen den [official guide](https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker) lesen.

```shell
mkdir -p /home/admin/jitsi/
wget https://raw.githubusercontent.com/jitsi/docker-jitsi-meet/master/docker-compose.yml -O /home/admin/jitsi/docker-compose.yml
wget https://raw.githubusercontent.com/jitsi/docker-jitsi-meet/master/env.example -O /home/admin/jitsi/.env

# generate new secrets
cd /home/admin/jitsi/
curl https://raw.githubusercontent.com/jitsi/docker-jitsi-meet/master/gen-passwords.sh | bash

# change configuration directory
sed -i 's|CONFIG=.*|CONFIG=/srv/jitsi|g' .env
```

Als Nächstes konfigurieren wir die `.env` Datei und richten die Port-Weiterleitungen für den jitsi/web Container:
```yaml
    web:
        image: jitsi/web:latest
        restart: ${RESTART_POLICY}
        ports:
            - '[::1]:${HTTP_PORT}:80'
        volumes:
            - ${CONFIG}/web:/config:Z
            ...
```

## OpenID Connect
Siehe [github.com/MarcelCoding/jitsi-openid#docker-compose](https://github.com/MarcelCoding/jitsi-openid#docker-compose)

## Configuration
Alle Konfigurationen werden in dem `/srv/jitsi` Ordner gespeichert: 
<ul>
  <li>
    Du kannst <code>/srv/jitsi/web/config.js</code>, because it will be regenerated on container start, but you can update the attributes in the .env file
  </li>
  <li>
    You can update the settings of your interface by modifying <code>/srv/jitsi/web/interface_config.js</code>
  </li>
</ul>


## Extend your Jitsi instance
### Etherpad
Etherpad allows you to edit documents collaboratively in real-time.

You can find the [etherpad.yml](https://github.com/jitsi/docker-jitsi-meet/blob/master/etherpad.yml) in which the service is defined, in the github repo.
I suggest you copy the etherpad service to your `docker-compose.yml`.
You can also add some environment variables to connect your own database. Your `.env` file should look like this:
```shell
DB_TYPE=postgres
DB_HOST=localhost
DB_PORT=5432
DB_NAME=etherpad
DB_USER=etherpad
DB_PASS=S3cR3T
#DB_CHARSET= This is only for MySQL
#DB_FILENAME= Just for SQLite or DirtyDB
```
Look also the [available database types](https://www.npmjs.com/package/ueberdb2). Now you have to put in these environment variables into your `docker-compose.yml`. This could look like this:
```yaml
    etherpad:
      environment:
        - ...
        - DB_TYPE=${DB_TYPE}
        - DB_HOST=${DB_HOST}
        - DB_PORT=${DB_PORT}
        - DB_NAME=${DB_NAME}
        - DB_USER=${DB_USER}
        - DB_PASS=${DB_PASS}
        - ...
```

### Jibri
The [Jitsi Broadcasting Infrastructure](https://github.com/jitsi/jibri) provides services for recording or streaming.

You can find the [jibri.yml](https://github.com/jitsi/docker-jitsi-meet/blob/master/jibri.yml) in which the service is defined, in the github repo.  
I suggest you copy the jibri service to your `docker-compose.yml`.

### Enable JVB Statictics (for monitoring)
You can enable the colibri api of the jvb service by simply comment out JVB_ENABLE_APIS in the .env file.
```shell
# A comma separated list of APIs to enable when the JVB is started [default: none]
# See https://github.com/jitsi/jitsi-videobridge/blob/master/doc/rest.md for more information
JVB_ENABLE_APIS=rest,colibri
```

You can now request the statistics from the api:
```shell
ip=$(docker inspect jitsi_jvb_1 | jq ".[0].NetworkSettings.Networks.jitsi.IPAddress" | tr -d '"')
curl -s "http://${ip}:8080/colibri/stats" | jq
```

## Export Metrics
You can export the metrics by using a prometheus exporter:
```yaml
    jitsi2prometheus:
        image: ghcr.io/an2ic3/jitsi2prometheus
        restart: always
		ports:
			- "[::1]:8000:8080"
        networks:
            meet.jitsi:
```

Don't forget to add your jitsi2prometheus instance to the prometheus configuration:
```yaml
...
scrape_configs:
   ...
  - job_name: 'jitsi'
    static_configs:
      - targets: ['[::1]:8080']
```
