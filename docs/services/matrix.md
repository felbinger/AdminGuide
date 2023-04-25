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

Bevor du den Container startest, musst du eine Konfigurationsdatei erstellen.
Der untenstehende Command erstellt eine `homeserver.yaml` Datei in dem Ordner `/srv/matrix`
```shell
docker run -it --rm -v "/srv/matrix/synapse:/data" \
  -e "SYNAPSE_SERVER_NAME=domain.de" \
  -e "SYNAPSE_REPORT_STATS=no" matrixdotorg/synapse generate
```

Danach solltest du die Postgresql Datenbank ähnlich wie hier konfigurieren:
```yaml
database:
  name: psycopg2
  args:
    user: synapse
    password: S3cr3T
    database: synapse
    host: postgres
    cp_min: 5
    cp_max: 10
```

Nicht vergessen die sqlite Datenbank auszukommentieren, welche von Matrix als Standard verwendet wird.
``` yaml
#database:
# name: sqlite3
# args:
# database: /data/homeserver.db
```

Jetzt kannst du den Service mit `docker-compose up -d` starten.

Wenn du nicht OpenID Connect verwendet willst (z.B. mit Keycloak), kannst du wie folgt Benutzer erstellen:
```yaml
sudo docker compose exec synapse register_new_matrix_user -u USERNAME -p PASSWORD -a -c /data/homeserver.yaml https://synapse.domain.de
```

### Benutzerpasswort zurücksetzen

Um ein Passwort zurückzusetzen, kannst du folgenden Befehl ausführen:
```shell
docker-compose exec -u www-data synapse hash_password -p PASSWORD
```

Wenn der Befehl ausgeführt wurde, bekommst du ein passwort hash als stdout.

Nachdem du ein Passwort hash erstellt hast, kannst du das Passwort in der Datenbank austauschen. 
Dazu musst du zuerst eine Shell in dem Postgres Container starten.
```shell
docker-compose exec postgres /bin/bash
```
Jetzt kannst du das Passwort updaten:
```shell
PGPASSWORD=S3cr3T \
  psql -U postgres -d synapse -c \
  "UPDATE users SET password_hash='$2a$12$xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' \
  WHERE name='@test:test.com';"
```

### Federation
```
;; SRV Records
_matrix._tcp.matrix.domain.de.    1    IN    SRV    10 5 443 matrix.domain.de.
```

### SSO with Keycloak

Wenn du einen *Keycloak* Service am Laufen hast, kannst du diesen als externen Authentifizierungsanbieter verwenden. 
Um diesen in Aktion zu bringen, müssen wir zuerst den Client in Keycloak erstellen. Als Client ID kannst du 
`synapse.domain.de` verwenden und `openid` als Protokoll. Den Rest des Clients kannst du wie folgt bearbeiten:

| Setting                      | Value                                                  |
|------------------------------|--------------------------------------------------------|
| Access Type                  | confidential                                           |
| Direct Access Grants Enabled | OFF                                                    |
| Root URL                     | `https://synapse.domain.de`                            |
| Valid Redirect URIs          | `https://synapse.domain.de` `http://synapse.domain.de` |
| Base URL                     | `https://synapse.domain.de`                            |
| Web Origins                  | +                                                      |

In dem "Credentials" Tab findest du den Client Secret. Diesen solltest du dir abspeichern, da wir ihn später noch
brauchen.

Jetzt müssen wir die `homeserver.yaml` Datei bearbeiten. Ich empfehle nach den Values zu suchen, da die Datei sehr lang
ist. Bearbeite folgende Zeilen wie unten:

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


**Wenn du den `openid` Scope nicht entfernst wird es nicht funktion!**

Wenn du den Matrix Server neu gestartet hast, solltest du dich mit Keycloak als SSO Provider anmelden können.

### Bridge Setup
Um die Bridges aufzusetzen, musst du nur den Anleitungen in den [docs]([https://docs.mau.fi/bridges/python/signal/setup-docker.html](https://docs.mau.fi/bridges/general/docker-setup.html))
folgen.