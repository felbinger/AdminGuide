# WordPress

```yaml
version: '3.9'

services:
  mysql:
    image: mysql
    restart: always
    env_file: .mysql.env
    environment:
      - "MYSQL_DATABASE=wordpress"
      - "MYSQL_USER=wordpress"
    volumes:
      - "/srv/wordpress/mysql:/var/lib/mysql"

  wordpress:
    image: wordpress
    restart: always
    env_file: .wordpress.env
    environment:
      - "WORDPRESS_DB_HOST=mysql:3306"
      - "WORDPRESS_DB_USER=wordpress"
      - "WORDPRESS_DB_NAME=wordpress"
    volumes:
      - "/srv/wordpress/plugins:/var/www/html/wp-content/plugins"
      - "/srv/wordpress/themes:/var/www/html/wp-content/themes"
      - "/srv/wordpress/uploads:/var/www/html/wp-content/uploads"
    ports:
      - "[::1]:8000:80"
```

```shell
# .mysql.env
MYSQL_PASSWORD=S3cr3T
```

```shell
# .wordpress.env
WORDPRESS_DB_PASSWORD=S3cr3T
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:80"
    ```

    ```nginx
    # /etc/nginx/sites-available/wordpress.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
    server {
        server_name wordpress.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/wordpress.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/wordpress.domain.de_ecc/wordpress.domain.de.key;
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
          - "traefik.http.services.srv_wordpress.loadbalancer.server.port=80"
          - "traefik.http.routers.r_wordpress.rule=Host(`wordpress.domain.de`)"
          - "traefik.http.routers.r_wordpress.entrypoints=websecure"
    ```
