# paperless

Paperless-NGX ist ein Open-Source-Dokumentenmanagementsystem, das darauf abzielt, die Verwaltung von Papierdokumenten
durch die Digitalisierung und Automatisierung von Geschäftsprozessen zu verbessern.

```yaml
version: '3.9'
	
services:
  broker:
    image: docker.io/library/redis:7
    restart: unless-stopped

  postgres:
    image: docker.io/library/postgres:15
    restart: unless-stopped
    env_file: .postgres.env
    environment:
      - "POSTGRES_DB=paperless"
    volumes:
      - "/srv/paperless/postgres:/var/lib/postgresql/data"

  gotenberg:
    image: docker.io/thecodingmachine/gotenberg:7.8
    restart: unless-stopped
    # The gotenberg chromium route is used to convert .eml files. We do not
    # want to allow external content like tracking pixels or even javascript.
    command:
      - "gotenberg"
      - "--chromium-disable-javascript=true"
      - "--chromium-allow-list=file:///tmp/.*"

  tika:
    image: ghcr.io/paperless-ngx/tika:latest
    restart: unless-stopped

  webserver:
    image: ghcr.io/paperless-ngx/paperless-ngx:latest
    restart: unless-stopped
    depends_on:
      - "broker"
      - "postgres"
      - "gotenberg"
      - "tika"
    ports:
      - "[::1]:8000:8000"
    healthcheck:
      test: ["CMD", "curl", "-fs", "-S", "--max-time", "2", "http://localhost:8000"]
      interval: 30s
      timeout: 10s
      retries: 5
    volumes:
      - "/srv/paperless/data:/usr/src/paperless/data"
      - "/srv/paperless/media:/usr/src/paperless/media"
      - "/srv/paperless/export:/usr/src/paperless/export"
      - "/srv/paperless/consume:/usr/src/paperless/consume"
    env_file: .paperless.env
    environment:
      - "PAPERLESS_REDIS=redis://broker:6379"
      - "PAPERLESS_DBHOST=postgres"
      - "PAPERLESS_TIKA_ENABLED=1"
      - "PAPERLESS_TIKA_GOTENBERG_ENDPOINT=http://gotenberg:3000"
      - "PAPERLESS_TIKA_ENDPOINT=http://tika:9998"
      - "PAPERLESS_TIME_ZONE=Europe/Berlin"
      - "PAPERLESS_OCR_LANGUAGE=deu"
      - "PAPERLESS_URL=https://paperless.domain.de"
```

```shell
# .postgres.env
POSTGRES_USER=paperless
POSTGRES_PASSWORD=S3cr3t-P4ssw0rd
```

```shell
# .paperless.env
PAPERLESS_DBUSER=paperless
PAPERLESS_DBPASS=S3cr3t-P4ssw0rd
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:8000"
    ```

    ```nginx
    # /etc/nginx/sites-available/paperless.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
    server {
        server_name paperless.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/paperless.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/paperless.domain.de_ecc/paperless.domain.de.key;
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
          - "traefik.http.services.srv_paperless.loadbalancer.server.port=8000"
          - "traefik.http.routers.r_paperless.rule=Host(`paperless.domain.de`)"
          - "traefik.http.routers.r_paperless.entrypoints=websecure"
    ```


## User erstellen
```shell
docker compose run --rm webserver ./manage.py createsuperuser
```

## Open ID Connect
Nicht verfügbar
bis [github.com/paperless-ngx/paperless-ngx/pull/1746](https://github.com/paperless-ngx/paperless-ngx/pull/1746)
gemerged ist.
