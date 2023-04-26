# Matrix

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
Federation ermöglicht die Kommunikation zwischen Nutzern verschiedener Homeserver.

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

### SSO with Keycloak

!!! info
    REWRITE REQUIRED

If you have an Instance of *Keycloak* running, you can use it as an external Authentication Provider.
At first, we have to create the Client in Keycloak. Create a new Client. Use `synapse.domain.de` as Client ID
and `openid` as Protocol. Edit your newly created Client as follows:

| Setting                      | Value                                                  |
|------------------------------|--------------------------------------------------------|
| Access Type                  | confidential                                           |
| Direct Access Grants Enabled | OFF                                                    |
| Root URL                     | `https://synapse.domain.de`                            |
| Valid Redirect URIs          | `https://synapse.domain.de` `http://synapse.domain.de` |
| Base URL                     | `https://synapse.domain.de`                            |
| Web Origins                  | +                                                      |

Now go to the "Credentials" Tab and save the Client Secret; we will need it later.


Now we have to edit the `homeserver.yaml` file. I suggest you search for the Values because the file is very long.
Uncomment / add and edit the following lines:

```
server_name: "matrix.domain.de"

enable_registration: false
password_config.enabled: false

oidc_providers:
# Keycloak
  - idp_id: keycloak
    idp_name: YOURNAME
    issuer: "https://id.domain.de/realms/main"
    client_id: "synapse.domain.de"
    client_secret: "YOURSECRET"
    scopes: ["profile"]
```

**It is very important to remove the `openid` Scope which is preset. Things will not work if the
`openid` Scope is set.**

Now restart your Matrix Server. You should now be able to log in with your Keycloak as an SSO Provider.

### Bridge Setup

Matrix unterstützt durch sogenannte Bridges die Einbindung anderer Messenger,
wie WhatsApp, Telegram, Signal, ... Auf der [offiziellen Website von Matrix](https://matrix.org/bridges/)
ist eine Liste mit allen unterstützten Anwendungen.

Die Einrichtung unterscheidet sich sehr stark je nach verwendeter Bridge, für
die oben (`docker-compose.yml`) auskommentierten Bridges sind die Installationsanweisungen
[hier](https://docs.mau.fi/bridges/python/signal/setup-docker.html](https://docs.mau.fi/bridges/general/docker-setup.html) zu finden