# passbolt

Passbolt ist ein self-hosted open source Passwortmanager, welcher sehr gut für Teams geeignet ist, durch die Funktion, 
dass man intern Passwörter teilen kann und Teams erstellen kann.

```yaml
version: '3.9'

services:
  postgres:
    image: postgres
    restart: always
    env_file: .postgres.env
    environment:
      - "POSTGRES_DB=passbolt"
    volumes:
      - "/srv/passbolt/postgres:/var/lib/postgresql/data"

  passbolt:
    image: passbolt/passbolt
    restart: always
    ports:
      - "[::1]:8000:80"
    env_file: .passbolt.env
    environment:
      - "APP_FULL_BASE_URL=https://passbolt.domain.de"
      - "DATASOURCES_DEFAULT_DRIVER=Cake\\Database\\Driver\\Postgres"
      - "DATASOURCES_DEFAULT_ENCODING=utf8"
      - "EMAIL_DEFAULT_FROM=passbolt@domain.de"
      - "EMAIL_TRANSPORT_DEFAULT_HOST=mail.domain.de"
      - "EMAIL_TRANSPORT_DEFAULT_PORT=587"
    volumes:
      - "/srv/passbolt/gpg:/passbolt/gpg"
      - "/srv/passbolt/jwt:/passbolt/jwt"
    command: >
      bash -c "/usr/bin/wait-for.sh -t 0 postgres:5432 -- /docker-entrypoint.sh"
```

```shell
# .postgres.env
POSTGRES_USER=passbolt
POSTGRES_PASSWORD=S3cr3t-P4ssw0rd
```

```shell
# .passbolt.env
DATASOURCES_DEFAULT_URL=postgres://passbolt:S3cr3t-P4ssw0rd@postgres:5432/passbolt?schema=passbolt
EMAIL_TRANSPORT_DEFAULT_USERNAME=passbolt@domain.de
EMAIL_TRANSPORT_DEFAULT_PASSWORD=PASSWORD_FOR_EMAIL_SERVER
EMAIL_TRANSPORT_DEFAULT_TLS=STARTTLS
```

=== "nginx"
    ```yaml
    ports:
      - "[::1]:8000:80"
    ```

    ```nginx
    # /etc/nginx/sites-available/passbolt.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
    server {
        server_name passbold.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/passbolt.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/passbolt.domain.de_ecc/passbolt.domain.de.key;
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
      - "traefik.http.services.srv_paperless.loadbalancer.server.port=80"
      - "traefik.http.routers.r_paperless.rule=Host(`passbolt.domain.de`)"
      - "traefik.http.routers.r_paperless.entrypoints=websecure"
    ```

## User erstellen
```shell
docker compose exec passbolt su -m -c "/usr/share/php/passbolt/bin/cake \
                                passbolt register_user \
                                -u <your@email.com> \
                                -f <yourname> \
                                -l <surname> \
                                -r admin" -s /bin/sh www-data
```

Für weitere Informationen siehe die offizielle [Dokumentation](https://help.passbolt.com/hosting/install/ce/docker.html)