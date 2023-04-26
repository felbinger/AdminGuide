# Seafile

Seafile ist eine sichere, Open-Source-Plattform für die Synchronisation, Freigabe und Zusammenarbeit von Dateien, die
sowohl eine On-Premises- als auch eine Cloud-basierte Bereitstellungsoption bietet.

```yaml
version: '3.9'

services:
  mariadb:
    image: mariadb   
    restart: always
    env_file: .mariadb.env
    volumes:
      - "/srv/seafile/mariadb:/var/lib/mysql"

  memcached:
    image: memcached
    restart: always
    entrypoint: memcached -m 256

  seafile:
    image: seafileltd/seafile-mc  
    restart: always
    env_file: .seafile.env
    environment:
      - "DB_HOST=mariadb"
      - "TIME_ZONE=Europe/Berlin"
      - "SEAFILE_SERVER_LETSENCRYPT=false"
      - "SEAFILE_SERVER_HOSTNAME=seafile.domain.de"
    volumes:
      - "/srv/seafile/data:/shared"
    ports:
      - "[::1]:8000:80"
```

```shell
# .mariadb.env
MYSQL_ROOT_PASSWORD=S3cr3T
```

```shell
# .seafile.env
DB_ROOT_PASSWD=S3cr3T
SEAFILE_ADMIN_EMAIL=admin@domain.de
SEAFILE_ADMIN_PASSWORD=S3cr3T
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:80"
    ```

    ```nginx
    # /etc/nginx/sites-available/seafile.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
    server {
        server_name seafile.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/seafile.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/seafile.domain.de_ecc/seafile.domain.de.key;
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
          - "traefik.http.services.srv_seafile.loadbalancer.server.port=80"
          - "traefik.http.routers.r_seafile.rule=Host(`seafile.domain.de`)"
          - "traefik.http.routers.r_seafile.entrypoints=websecure"
    ```

