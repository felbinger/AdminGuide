# TeamSpeak

TeamSpeak ist eine Voice-over-IP-Software, die es Benutzern ermöglicht, über das Internet miteinander zu kommunizieren.

```yaml
services:
  mariadb:
    image: mariadb
    restart: always
    env_file: .mariadb.env
    environment:
      - "MYSQL_RANDOM_ROOT_PASSWORD=yes"
      - "MYSQL_DATABASE=teamspeak"
      - "MYSQL_USER=teamspeak"
    volumes:
      - "/srv/teamspeak3/mariadb:/var/lib/mysql"

  teamspeak3:
    image: teamspeak
    restart: always
    env_file: .teamspeak3.env
    environment:
      - "TS3SERVER_DB_PLUGIN=ts3db_mariadb"
      - "TS3SERVER_DB_USER=teamspeak"
      - "TS3SERVER_DB_NAME=teamspeak"
      - "TS3SERVER_DB_SQLCREATEPATH=create_mariadb"
      - "TS3SERVER_DB_HOST=mariadb"
      - "TS3SERVER_DB_WAITUNTILREADY=30"
      - "TS3SERVER_LICENSE=accept"
    volumes:
      - "/srv/teamspeak3/data:/var/ts3server/"
    ports:
      - '9987:9987/udp'  # voice
      - '30033:30033'    # filetransfer

  sinusbot:
    image: sinusbot/docker
    restart: always
    ports:
      - "[::1]:8000:8087"
    volumes:
      - "/srv/sinusbot/scripts:/opt/sinusbot/scripts"
      - "/srv/sinusbot/data:/opt/sinusbot/data"
```

```shell
# .mariadb.env
MYSQL_PASSWORD=S3cr3T
```

```shell
# .teamspeak3.env
TS3SERVER_DB_PASSWORD=S3cr3t
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:8087"
    ```

    ```nginx
    # /etc/nginx/sites-available/sinusbot.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
    server {
        server_name sinusbot.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/sinusbot.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/sinusbot.domain.de_ecc/sinusbot.domain.de.key;
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
            proxy_pass http://[::1]:8000/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header X-Real-IP $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
    }
    ```

=== "Traefik"
    ```yaml
        labels:
          - "traefik.enable=true"
          - "traefik.http.services.srv_sinusbot.loadbalancer.server.port=8087"
          - "traefik.http.routers.r_sinusbot.rule=Host(`sinusbot.domain.de`)"
          - "traefik.http.routers.r_sinusbot.entrypoints=websecure"
    ```

Nach dem ersten Containerstart werden in den Logs des Containers,
- die Teamspeak Server Query Zugangsdaten,
- der Teamspeak Berechtigungstoken, sowie
- das MariaDB Root Passwort
ausgegeben. Wir empfehlen die Daten an einem sicheren Ort zu speichern.

### Server Query Zugangsdaten zurücksetzen
Sofern Sie die TeamSpeak Server Query Zugangsdaten vergessen haben,
können Sie diese mithilfe des folgenden Befehls zurücksetzen:

```shell
sudo docker compose run --rm teamspeak3 ts3server \
  inifile=/var/run/ts3server/ts3server.ini \
  serveradmin_password=NEW_PASSWORD
```

Anschließend kann man sich innerhalb des ts3server Containers
mit dem Server Query Interface verbinden und dort einen neuen
Berechtigungstoken erstellen:
```sh
sudo docker compose run --rm teamspeak3 nc localhost 10011
```
```sh
login serveradmin NEW_PASSWORD
# use server 1 (default)
use 1
# add a new admin token
tokenadd tokentype=0 tokenid1=6 tokenid2=0
```