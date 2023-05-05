# Matrix

Ein Server für einen dezentralen Messenger Dienst.

```yaml
version: '3.9'

services:
  postgres:
    image: postgres
    restart: always
    env_file: .postgres.env
    environment:
      - "POSTGRES_DB=synapse"
      - "POSTGRES_USER=synapse"
      - "POSTGRES_INITDB_ARGS=-E UTF8 --lc-collate=C --lc-ctype=C"
    volumes:
      - "/srv/matrix/postgres:/var/lib/postgresql/data"

  synapse:
    image: matrixdotorg/synapse
    restart: always
    volumes:
      - "/srv/matrix/synapse:/data"
    ports:
      - "[::1]:8000:8008"

#  mautrix-signal:
#    image: dock.mau.dev/mautrix/signal
#    restart: always
#    depends_on:
#      - "signald"
#    volumes:
#      - "/srv/matrix/mautrix-signal:/data"
#      - "/srv/signald:/signald"
#
#  signald:
#    image: docker.io/signald/signald
#    restart: always
#    volumes: 
#      - "/srv/signald:/signald"

#  mautrix-telegram:
#    image: dock.mau.dev/mautrix/telegram
#    restart: always
#    volumes:
#      - "/srv/matrix/mautrix-telegram:/data"

#  mautrix-whatsapp:
#    image: dock.mau.dev/mautrix/whatsapp
#    restart: always
#    volumes:
#      - "/srv/matrix/mautrix-whatsapp:/data"
#      - "/etc/timezone:/etc/timezone:ro"
```

```shell
# .postgres.env
POSTGRES_PASSWORD=S3cr3T
```

=== "nginx"
    ```yaml
    ports:
    - "[::1]:8000:8080"
    ```

    ```nginx
    # /etc/nginx/sites-available/synapse.domain.de.conf
    # https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
    server {
        server_name synapse.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/synapse.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/synapse.domain.de_ecc/synapse.domain.de.key;
        ssl_session_timeout 1d;
        ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
        ssl_session_tickets off;

        # modern configuration
        ssl_protocols TLSv1.3;
        ssl_prefer_server_ciphers off;

        # HSTS (ngx_http_headers_module is required) (63072000 seconds)
        add_header Strict-Transport-Security "max-age=63072000" always;

        # OCSP stapling
        ssl_stapling on;
        ssl_stapling_verify on;

        location / {
            return 301 https://app.element.io$request_uri;
        }

        location ~* ^(\/_matrix|\/_synapse\/client) {
            proxy_pass http://[::1]:8000;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header X-Real-IP $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;

            # Nginx by default only allows file uploads up to 1M in size
            # Increase client_max_body_size to match max_upload_size defined in homeserver.yaml
            client_max_body_size 50M;
        }
    }
    ```

    Die beiden Dateien `server` und `client` im Verzeichnis `.well-known/matrix` 
    müssen auf der Homeserver Domain (hier `domain.de`) hinterlegt sein, damit 
    die Matrix Federation funktioniert und Clients details zum Homeserver erhalten.

    ```nginx
    # /etc/nginx/sites-available/domain.de.conf
    # https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
    server {
        server_name domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/domain.de_ecc/domain.de.key;
        ssl_session_timeout 1d;
        ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
        ssl_session_tickets off;

        # modern configuration
        ssl_protocols TLSv1.3;
        ssl_prefer_server_ciphers off;

        # HSTS (ngx_http_headers_module is required) (63072000 seconds)
        add_header Strict-Transport-Security "max-age=63072000" always;

        # OCSP stapling
        ssl_stapling on;
        ssl_stapling_verify on;

        location /.well-known/matrix/server {
            add_header content-type application/json;
            add_header access-control-allow-headers "Origin, X-Requested-With, Content-Type, Accept, Authorization";
            add_header access-control-allow-methods "GET, POST, PUT, DELETE, OPTIONS";
            add_header access-control-allow-origin *;
            return 200 '{"m.server":"synapse.domain.de:443"}';
        }

        location /.well-known/matrix/client {
            add_header content-type application/json;
            add_header access-control-allow-headers "Origin, X-Requested-With, Content-Type, Accept, Authorization";
            add_header access-control-allow-methods "GET, POST, PUT, DELETE, OPTIONS";
            add_header access-control-allow-origin *;
            return 200 '{"m.homeserver":{"base_url":"https://synapse.domain.de"},"m.identity_server":{"base_url":"https://vector.im"},"im.vector.riot.jitsi": {"preferredDomain": "meet.ffmuc.net"}}';
        }
    }
    ```

=== "Traefik"
    ```yaml
    labels:
    - "traefik.enable=true"
    - "traefik.http.services.srv_synapse.loadbalancer.server.port=8008"
    - "traefik.http.routers.r_synapse.rule=Host(`synapse.domain.de`)"
    - "traefik.http.routers.r_synapse.entrypoints=websecure"
    ```

    TODO `.well-known/matrix/{server,client}` auf `domain.de`


Als erstes, muss die homeserver-Konfiguration generiert werden. Dazu wird folgender Befehl ausgeführt:
```shell
docker run -it --rm -v "/srv/matrix/synapse:/data" \
  -e "SYNAPSE_SERVER_NAME=domain.de" \
  -e "SYNAPSE_REPORT_STATS=no" matrixdotorg/synapse generate
```

Anschließend wird die Datenbankkonfiguration in der `/srv/matrix/synapse/homeserver.yaml` angepasst:
```yaml
database:
  # name: sqlite3
  # args:
  # database: /data/homeserver.db
  name: psycopg2
  args:
    user: synapse
    password: S3cr3T
    database: synapse
    host: postgres
    cp_min: 5
    cp_max: 10
```

Nun kann der Matrix Homeserver bereits mit dem Befehl `docker compose up -d` gestartet werden.


### Lokalen Nutzer anlegen
Ein neuer Nutzer lässt sich mit diesem Befehl erzeugen:
```shell
sudo docker compose exec synapse register_new_matrix_user \
  -u USERNAME -p PASSWORD \
  -a -c /data/homeserver.yaml http://localhost:8008
```

### Passwort zurücksetzen
Zurücksetzen lassen sich die Passwörter lediglich über den Datenbank.
Zunächst wird ein neuer hash generiert, anschließend wird dieser
in der Datenbank für den jeweiligen Nutzer als Password ersetzt.

```shell
new=$(sudo docker compose exec -u www-data synapse hash_password -c /data/homeserver.yaml -p PASSWORD)
sudo docker compose exec postgres psql -U postgres -d synapse -c \
  "UPDATE users SET password_hash='${new}' WHERE name='@test:domain.de';"
```

### Federation
Eine Federation ermöglicht die Kommunikation zwischen Nutzern verschiedener Homeserver.

Wenn der Synapse Homeserver direkt auf der Domain aufgesetzt
ist die im Homeserver eingerichtet ist, funktioniert dies out-of-the-box.

Wird der Synapse Server (hier: `synapse.domain.de`) nicht auf
der Domain des Homeservers (hier: `domain.de`) erreichbar gemacht,
gibt es zwei Möglichkeiten die Ferderation einzurichten.

Der `_matrix` SRV DNS Record kann hierfür genutzt werden.
Dies hat jedoch den Nachteil, das zwangsläufig die IP
Adresse des Matrix Servers geleakt wird, selbst wenn
Cloudflare Proxy verwendet wird, da synapse.domain.de
dann nicht geproxied werden kann.
```
_matrix._tcp.domain.de. 1 IN SRV 10 5 443 synapse.domain.de.
```

Die aus meiner Sicht bessere Alternative ist die Erstellung
von zwei Dateien im Verzeichnis `.well-known/matrix` des Webservers
der Homeserver Domain. Selbst wenn andere Dienste auf dieser Domain
(z.B. eine Website, Nextcloud, ...) betrieben werden kommen sich
diese Dateien damit nicht in die Quere.

Wird nginx als Reverse Proxy betrieben so müssen lediglich diese
beiden locations in den V-Host für `domain.de` eingefügt werden.
```nginx
location /.well-known/matrix/server {
    add_header content-type application/json;
    add_header access-control-allow-headers "Origin, X-Requested-With, Content-Type, Accept, Authorization";
    add_header access-control-allow-methods "GET, POST, PUT, DELETE, OPTIONS";
    add_header access-control-allow-origin *;
    return 200 '{"m.server":"synapse.domain.de:443"}';
}

location /.well-known/matrix/client {
    add_header content-type application/json;
    add_header access-control-allow-headers "Origin, X-Requested-With, Content-Type, Accept, Authorization";
    add_header access-control-allow-methods "GET, POST, PUT, DELETE, OPTIONS";
    add_header access-control-allow-origin *;
    return 200 '{"m.homeserver":{"base_url":"https://synapse.domain.de"},"m.identity_server":{"base_url":"https://vector.im"},"im.vector.riot.jitsi": {"preferredDomain": "meet.ffmuc.net"}}';
}
```
Die Dateien können auch Manuell angelegt werden, falls die
Homeserver-Domain z. B. auf einen Webspace zeigt.

Falls Cloudflare Proxy genutzt wird, ist gegebenenfalls noch
[dieses](https://github.com/marcelcoding/.well-known) Projekt interessant.

Es ermöglicht die zentrale Konfiguration von HTTP Seiten, die auf allen Domains,
die durch Cloudflare Proxy gerouted werden aufgerufen werden können. Dies ist vor
allem für Seiten wie die [`.well-known/security.txt`](https://securitytxt.org) oder
`robots.txt` Interessant, doch auch die `.well-known` Einträge für Matrix können so
gesetzt werden.

### Single Sign-On

Prinzipiell bietet Synapse auch Unterstütztung für SSO (z. B. Open ID Connect). Sofern Matrix Bridges
eingesetzt werden - wovon ich hier mal ausgehe, da sonst auch einfach ein offizieller Matrix Homeserver
([`matrix.org`](https://app.element.io) / [`mozilla.org`](https://chat.mozilla.org)) verwendet werden
kann - würde ich jedoch zumindest von mehreren Nutzern auf dem gleichen Homeserver abraten.

Synapse kann ohne Probleme mit mehreren Benutzern genutzt werden, bei der WhatsApp Bridge konnte ich auf
einem Homeserver mit zwei Nutzern einige "Unschönheiten" feststellen.

!!! info "Beispiel: WhatsApp Status Broadcasts"
Nutzer A hat die Nummer von Nutzer B in seinen Kontakten eingespeichert.  
Nutzer A erstellt einen WhatsApp Status in der App, und fügt Nutzer B zu den Empfängern hinzu.  
Die Bridge von Nutzer B empfängt den Status Broadcast und fügt Nutzer B in den Status Broadcast
Chatroom von Nutzer A hinzu, wodurch Nutzer B alle alten und zukünftigen (sofern Nutzer A
Nutzer B nicht wieder rauswirft) Status Nachrichten von Kontakten von Nutzer A sieht.
Der Nutzer sieht diese Status Nachrichten aber nicht nur, in der Übersicht in dem WhatsApp Client wird der Person
auch angezeigt, dass eine (meistens fremde Nummer) diesen Status gesehen hat. Somit bekommen die WhatsApp Kontakte
auch davon mit.


### Bridge Setup

Matrix unterstützt durch sogenannte Bridges die Einbindung anderer Messenger,
wie WhatsApp, Telegram, Signal, ... Auf der [offiziellen Website von Matrix](https://matrix.org/bridges/)
ist eine Liste mit allen unterstützten Anwendungen.

Die Einrichtung unterscheidet sich sehr stark je nach verwendeter Bridge, für
die oben (`docker-compose.yml`) auskommentierten Bridges sind die Installationsanweisungen
[hier](https://docs.mau.fi/bridges/python/signal/setup-docker.html) zu finden.

## Mautrix-WhatsApp (WhatsApp Bridge)
Nachdem die `docker-compose.yml` entsprechend bearbeitet wurde und der Container neu gestartet wurde, gibt es noch
einige Konfigurationen, welche man vornehmen muss, damit die Bridge funktioniert.

Bevor wir mit der Konfiguration beginnen können, müssen wir dem Service eine eigene
Datenbank anlegen.
Die Datenbank erstellt man wie folgt:

```shell
sudo docker compose exec postgres psql -U postgres -d synapse -c 'CREATE DATABASE "mautrix-whatsapp";'
```

In dem Ordner `/srv/matrix/mautrix-whatsapp/` befindet sich jetzt eine sogenannte `config.yaml`. Wenn man sich diese
anschaut bemerkt man, dass dort ziemlich viel drin steht. An sich kann alles auch bearbeitet und geändert werden, aber
ein paar Einstellungen welche vorgenommen werden müssen sind hier jetzt aufgeführt.
(In dem unten aufgeführten Codeblock sind nur die Einstellungen welche geändert werden müssen und somit stehen auch nicht
die Kommentare in dem Codeblock, welche in der Datei auf dem Server stehen).

```yaml
homeserver:
  address: https://matrix.example.com      <--- Hier die Matrix Sub-Domain angeben
  domain: example.com                      <--- Hier die Matrix Homeserver Domain (welche hinter dem Namen steht)

appservice:
  address: http://mautrix-whatsapp:29318   <--- Dies so kopieren

  database:
    uri: postgres://postgres@postgres/mautrix-whatsapp?sslmode=disable  <--- Dies auch kopieren
```

Unter dem Abschnitt `bridge:` befinden sich viele Konfigurationen, welche die Bridge an sich betreffen. Diese müssen
nach den persönlichen vorlieben eingestellt werden. Wir empfehlen aus den oben genannten Gründen die WhatsApp Bridge 
nicht jedem Nutzer auf dem Homeserver zur Verfügung zu stellen, deswegen empfehlen wir folgende Einstellung vorzunehmen.

```yaml
bridge:
  permissions:
    "*": relay
    "example.com": user                  <--- Diese Zeile entfernen
    "@admin:example.com": admin          <--- Das in Anführungszeichen zu dem Matrix Namen des Admins ändern.
```

Wenn man die Konfigurationsdatei abgespeichert und den Container neu gestartet hat, befindet sich neben der `config.yaml`
jetzt auch eine `registration.yaml`. Diese Datei muss in `/srv/matrix/synapse/` verschoben werden und wenn man vorhat
mehrere Bridges zu verwenden empfehlen wir diese auch in `whatsapp-registration.yaml` o. Ä.  umzubenennen.
Wenn die Datei verschoben und ggf. umbenannt wurde muss man diese in die `homeserver.yaml` Datei hinzufügen, indem man
am Ende der Datei folgende zwei Zeilen hinzufügt:

```yaml
app_service_config_files:
  - /data/whatsapp-registration.yaml
```

Wenn der Container nun erneut neu gestartet wurde, kann man in seiner Matrix Instanz den Benutzer `@whatsappbot:domain.de`
(sofern der Name des Bots in der `config.yaml` nicht verändert wurde) anschreiben und mit der Nachricht `help` eine
Hilfenachricht erhalten.