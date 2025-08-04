# Keycloak

Keycloak ist eine Software zur Verwaltung von Benutzer-Authentifizierung und Autorisierung, einschließlich
Single-Sign-On und Social-Login, für Anwendungen und Services.

```yaml
services:
  postgres:
    image: postgres
    restart: always
    env_file: .postgres.env
    environment:
      - "POSTGRES_USER=keycloak"
      - "POSTGRES_DB=keycloak"
    volumes:
      - "/srv/keycloak/postgres:/var/lib/postgresql/data"

  keycloak:
    image: ghcr.io/secshellnet/keycloak
    restart: always
    command: start
    env_file: .keycloak.env
    environment:
      - "KC_DB_URL_HOST=postgres"
      - "KC_DB_USERNAME=keycloak"
      - "KC_DB_URL_DATABASE=keycloak"
      - "KC_PROXY=edge"
      - "KC_HOSTNAME_STRICT=false"
    ports:
      - "[::1]:8000:8080"
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
```

```shell
# .postgres.env
POSTGRES_PASSWORD=S3cr3T
```

```shell
# .keycloak.env
KC_DB_PASSWORD=S3cr3T
KC_ADMIN=kcadmin
KC_ADMIN_PASSWORD=S3cr3T
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:8080"
    ```

    Das Administrative Webinterface zur Verwaltung der Realms möchte man
    für gewöhnlich nicht aus dem Internet erreichbar haben. Daher erstellen
    wir zwei Virtual Hosts, einen für Administrative Zwecke und einen für
    die normale Anmeldung, der auch aus dem Internet erreichbar ist.

    ```nginx
    # /etc/nginx/sites-available/id.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
    server {
        server_name id.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/id.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/id.domain.de_ecc/id.domain.de.key;
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

        # redirect to account login
        location ~* ^(\/)$ {
            return 301 https://id.secshell.net/realms/main/account/;
        }

        # do not allow keycloak admin from this domain
        location ~* (\/admin\/|\/realms\/master\/) {
            return 403;
        }
    }
    ```

    ```nginx
    # /etc/nginx/sites-available/keycloak.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
    server {
        server_name keycloak.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/keycloak.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/keycloak.domain.de_ecc/keycloak.domain.de.key;
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

        # redirect to admin console
        location ~* ^(\/)$ {
            return 301 https://keycloak.domain.de/admin/master/console/;
        }
    }
    ```

=== "Traefik"
    ```yaml
        labels:
          - "traefik.enable=true"
          - "traefik.http.services.srv_keycloak.loadbalancer.server.port=8080"
          - "traefik.http.routers.r_keycloak.rule=Host(`keycloak.domain.de`)"
          - "traefik.http.routers.r_keycloak.entrypoints=websecure"
    ```
