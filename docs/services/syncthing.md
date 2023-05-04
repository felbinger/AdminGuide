# Syncthing

Software zum Synchronisieren und Versionieren von Dateien.

```yaml
version: '3.9'

services:
  syncthing:
    image: syncthing/syncthing
    restart: always
    volumes:
      - "/srv/syncthing:/var/syncthing"
    ports:
      - "22000:22000"
      - "[::1]:8000:8384"
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:8384"
    ```

    ```nginx
    # /etc/nginx/sites-available/syncthing.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
    server {
        server_name syncthing.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/syncthing.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/syncthing.domain.de_ecc/syncthing.domain.de.key;
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
          - "traefik.http.services.srv_syncthing.loadbalancer.server.port=8384"
          - "traefik.http.routers.r_syncthing.rule=Host(`syncthing.domain.de`)"
          - "traefik.http.routers.r_syncthing.entrypoints=websecure"
    ```