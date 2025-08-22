# Gitea

Gitea ist eine webbasierte Git-Plattform, die es Benutzern ermöglicht, Code-Repositories zu hosten, zu verwalten und zu
teilen.

```yaml
services:
  gitea:
    image: gitea/gitea
    restart: always
    ports:
      - "[::1]:8000:3000"
      - "2222:22"
    volumes:
      - "/srv/gitea:/data"
      - "/etc/timezone:/etc/timezone:ro"
      - "/etc/localtime:/etc/localtime:ro"
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:3000"
    ```

    ```nginx
    # /etc/nginx/sites-available/gitea.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.27.3&config=modern&openssl=3.4.0&ocsp=false&guideline=5.7
    server {
        server_name gitea.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/gitea.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/gitea.domain.de_ecc/gitea.domain.de.key;
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
          - "traefik.http.services.srv_gitea.loadbalancer.server.port=3000"
          - "traefik.http.routers.r_gitea.rule=Host(`gitea.domain.de`)"
          - "traefik.http.routers.r_gitea.entrypoints=websecure"
    ```

## OpenID/KeyCloak
* Server Settings -> `Authentication Sources` -> OAuth2 -> OpenID-Connect
* Discovery URL: `https://id.domain.de/auth/realms/<realm>/.well-known/openid-configuration`
