# Privatebin

PrivateBin ist eine Open-Source-Webanwendung, welche die sichere gemeinsame Nutzung von Text- und Dateiinhalten ermöglicht,
indem sie diese verschlüsselt und nur für autorisierte Benutzer zugänglich macht.

```yaml
version: '3.9'

services:
  privatebin:
    image: privatebin/nginx-fpm-alpine
    restart: always
    ports:
      - "[::1]:8000:8080"
    volumes:
      - "/srv/privatebin:/srv/data"
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:8080"
    ```

    ```nginx
    # /etc/nginx/sites-available/privatebin.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
    server {
        server_name privatebin.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/privatebin.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/privatebin.domain.de_ecc/privatebin.domain.de.key;
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
          - "traefik.http.services.srv_privatebin.loadbalancer.server.port=8080"
          - "traefik.http.routers.r_privatebin.rule=Host(`privatebin.domain.de`)"
          - "traefik.http.routers.r_privatebin.entrypoints=websecure"
    ```