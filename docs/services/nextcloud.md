# Nextcloud

Nextcloud ist eine vielseitige Cloud, welche mit zahlreichen Add-ons um Funktionen erweitert werden kann.

```yaml
services:
  postgres:
    image: postgres
    restart: always
    env_file: .postgres.env
    environment:
      - "POSTGRES_DB=nextcloud"
      - "POSTGRES_USER=nextcloud"
    volumes:
      - "/srv/nextcloud/postgres:/var/lib/postgresql/data"

  redis:
    image: redis
    restart: always

  nextcloud:
    image: nextcloud
    restart: always
    env_file: .nextcloud.env
    environment:
      - "POSTGRES_HOST=postgres"
      - "POSTGRES_DB=nextcloud"
      - "POSTGRES_USER=nextcloud"
      - "NEXTCLOUD_TRUSTED_DOMAINS=nextcloud.domain.de"
      - "REDIS_HOST=redis"
    volumes:
      - "/srv/nextcloud/data:/var/www/html"
    ports:
      - "[::1]:8000:80"
```

```shell
# .postgres.env
POSTGRES_PASSWORD=S3cr3T
```

```shell
# .nextcloud.env
POSTGRES_PASSWORD=S3cr3T
NEXTCLOUD_ADMIN_USER=username
NEXTCLOUD_ADMIN_PASSWORD=p4ssw0rd
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:80"
    ```

    ```nginx
    # /etc/nginx/sites-available/nextcloud.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.27.3&config=modern&openssl=3.4.0&ocsp=false&guideline=5.7
    server {
        server_name nextcloud.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/nextcloud.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/nextcloud.domain.de_ecc/nextcloud.domain.de.key;
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
          - "traefik.http.services.srv_nextcloud.loadbalancer.server.port=80"
          - "traefik.http.routers.r_nextcloud.rule=Host(`nextcloud.domain.de`)"
          - "traefik.http.routers.r_nextcloud.entrypoints=websecure"
    ```

## Cronjobs
Um Cronjobs unter Nextcloud einzurichten, empfehlen wir Folgendes:

1. Stelle in dem Nextcloud Webinterface unter `Administration-Settings -> Basic settings` die Background jobs auf `cron`

2. Öffne den crontab auf dem Server mit folgendem Befehl: `sudo crontab -e`

3. Füge unten folgende Zeile ein: `*/5  *  *  *  *  docker exec -u www-data nextcloud-nextcloud-1 php -d memory_limit=-1 -f cron.php`

## Open ID Connect
[janikvonrotz.ch/2020/10/20/openid-connect-with-nextcloud-and-keycloak/](https://janikvonrotz.ch/2020/10/20/openid-connect-with-nextcloud-and-keycloak/)
