# Vaultwarden

Vaultwarden ist eine Open-Source-Serveranwendung für das sichere Speichern und Verwalten von Passwörtern und anderen
vertraulichen Informationen in einem persönlichen Tresor.

```yaml
version: '3.9'

services:
  postgres:
    image: postgres:15
    restart: always
    env_file: .postgres.env
    environment:
      - "POSTGRES_DB=vaultwarden"
      - "POSTGRES_USER=vaultwarden"
    volumes:
      - "/srv/vaultwarden/postgres:/var/lib/postgresql/data"

  vaultwarden:
    image: vaultwarden/server:alpine
    restart: always
    env_file: .vaultwarden.env
    environment:
      - "DOMAIN=https://vaultwarden.domain.de"
      - "SIGNUPS_ALLOWED=false"
      - "INVITATIONS_ALLOWED=false"
      - "SHOW_PASSWORD_HINT=false"
    ports:
      - "[::1]:8000:80"
    volumes:
      - "/srv/vaultwarden/data:/data/"
```

```shell
# .postgres.env
POSTGRES_PASSWORD=S3cr3T
```

```shell
# .vaultwarden.env
DATABASE_URL=postgresql://vaultwarden:S3cr3T@postgres/vaultwarden
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:80"
    ```

    ```nginx
    # /etc/nginx/sites-available/vaultwarden.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
    server {
        server_name vaultwarden.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/vaultwarden.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/vaultwarden.domain.de_ecc/vaultwarden.domain.de.key;
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
          - "traefik.http.services.srv_vaultwarden.loadbalancer.server.port=80"
          - "traefik.http.routers.r_vaultwarden.rule=Host(`vaultwarden.domain.de`)"
          - "traefik.http.routers.r_vaultwarden.entrypoints=websecure"
    ```
