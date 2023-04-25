# Jitsi

!!! info ""
	Dadurch, dass der dockerized Jitsi service nicht unbedingt sehr angenehm ist, empfehlen wir dafür einen separaten 
	virtuellen Server.
	Hierfür haben wir folgende Skripte [jitsi](https://github.com/secshellnet/docs/blob/main/scripts/jitsi.sh)
	und [jitsi-oidc](https://github.com/secshellnet/docs/blob/main/scripts/jitsi-oidc.sh).

Bei Problemen den [official guide](https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker) lesen.

```shell
mkdir -p /home/admin/jitsi/
wget https://raw.githubusercontent.com/jitsi/docker-jitsi-meet/master/docker-compose.yml -O /home/admin/jitsi/docker-compose.yml
wget https://raw.githubusercontent.com/jitsi/docker-jitsi-meet/master/env.example -O /home/admin/jitsi/.env

# generiert neue secrets
cd /home/admin/jitsi/
curl https://raw.githubusercontent.com/jitsi/docker-jitsi-meet/master/gen-passwords.sh | bash

# ändert den Konfigurationsordner
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

## Konfiguration
Alle Konfigurationen werden in dem `/srv/jitsi` Ordner gespeichert: 
<ul>
  <li>
    Du kannst <code>/srv/jitsi/web/config.js</code>, because it will be regenerated on container start, but you can update the attributes in the .env file
  </li>
  <li>
    You can update the settings of your interface by modifying <code>/srv/jitsi/web/interface_config.js</code>
  </li>
</ul>


## Erweiterung der Jitsi Instanz
### Etherpad
Etherpad ermöglicht es Dokumente gemeinsam in Echtzeit zu bearbeiten.

Die [etherpad.yml](https://github.com/jitsi/docker-jitsi-meet/blob/master/etherpad.yml), wo der Service beschrieben ist,
befindet sich in deren GitHub repo.
Wir empfehlen den Etherpad-Service in die `docker-compose.yml` zu kopieren.
Außerdem kann man die Umgebungsvariablen für das Verbinden mit deiner eigenen Datenbank anlegen. Die `.env` Datei
sollte ungefähr so aussehen:
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
Beachte [verfügbare Datenbanktypen](https://www.npmjs.com/package/ueberdb2).
Jetzt müssen die angelegten Umgebungsvariablen in die `docker-compose.yml` hinzugefügt werden. Ungefähr wie hier:
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
Die [Jitsi Broadcasting Infrastruktur](https://github.com/jitsi/jibri) ermöglicht das Aufnehmen und Streamen in einem
Jitsi Meeting.

Die Konfigurationen befinden sich in der [jibri.yml](https://github.com/jitsi/docker-jitsi-meet/blob/master/jibri.yml),
welche man in dem zugehörigem GitHub repo findet.
Wir empfehlen den Dienst in die `docker-compose.yml` zu kopieren.

### JVB Statictics (für monitoring)

Die Colibri API von dem JVB Dienst kann aktiviert werden, indem man die JVB_ENABLE_APIS in der `.env` Datei
auskommentiert.
```shell
# Eine mit Kommata separierte Liste mit API Schnittstellen, welche gestartet werden soll wenn das JVB startet [default: none]
# Siehe https://github.com/jitsi/jitsi-videobridge/blob/master/doc/rest.md für mehr Informationen
JVB_ENABLE_APIS=rest,colibri
```

Die API ist nun verfügbar und du kannst die Daten abfragen:
```shell
ip=$(docker inspect jitsi_jvb_1 | jq ".[0].NetworkSettings.Networks.jitsi.IPAddress" | tr -d '"')
curl -s "http://${ip}:8080/colibri/stats" | jq
```

## Metrics exportieren
Die Metrics kannst du mithilfe von dem Prometheus Exporter exportieren und einsehen:

```yaml
    jitsi2prometheus:
        image: ghcr.io/an2ic3/jitsi2prometheus
        restart: always
		ports:
			- "[::1]:8000:8080"
        networks:
            meet.jitsi:
```

Zum Hinzufügen der jitsi2prometheus Instanz in den prometheus muss folgendes in der prometheus Konfiguration hinzugefügt
werden:

```yaml
...
scrape_configs:
   ...
  - job_name: 'jitsi'
    static_configs:
      - targets: ['[::1]:8080']
```
