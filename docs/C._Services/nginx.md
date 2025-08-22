# nginx

Wird ein einfacher Webserver z. B. für eine statische Homepage benötigt, kann ein nginx Container verwendet werden.

!!! info ""
    Sofern sie als Reverse Proxy nginx Verwenden, können Sie auch einfach einen
    neuen Virtual Host auf diesem für ihre Homepage erstellen.

    ```nginx
    # /etc/nginx/sites-available/homepage.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.27.3&config=modern&openssl=3.4.0&ocsp=false&guideline=5.7
    server {
        server_name homepage.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/homepage.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/homepage.domain.de_ecc/homepage.domain.de.key;
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
            root /srv/homepage/;
            index index.html;
        }
    }
    ```

```yaml
services:
  homepage:
    image: nginx:alpine
    restart: always
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_homepage.loadbalancer.server.port=80"
      - "traefik.http.routers.r_homepage.rule=Host(`homepage.domain.de`)"
      - "traefik.http.routers.r_homepage.entrypoints=websecure"
    volumes:
      - "/srv/homepage:/usr/share/nginx/html/"
```

=== "Traefik"
    ```yaml
        labels:
          - "traefik.enable=true"
          - "traefik.http.services.srv_homepage.loadbalancer.server.port=80"
          - "traefik.http.routers.r_homepage.rule=Host(`homepage.domain.de`)"
          - "traefik.http.routers.r_homepage.entrypoints=websecure"
    ```
