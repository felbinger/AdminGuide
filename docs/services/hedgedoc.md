# HedgeDoc

HedgeDoc ist eine Open-Source-Plattform für die kollaborative Bearbeitung von Dokumenten in Echtzeit, ähnlich wie Google
Docs oder Microsoft Office Online.

```yaml
services:
  postgres:
    image: postgres
    restart: always
    env_file: .postgres.env
    environment:
      - "POSTGRES_DB=hedgedoc"
      - "POSTGRES_USER=hedgedoc"
    volumes:
      - "/srv/hedgedoc/postgres:/var/lib/postgresql/data"

  hedgedoc:
    image: quay.io/hedgedoc/hedgedoc
    restart: always
    env_file: .hedgedoc.env
    environment:
      - "CMD_DOMAIN=hedgedoc.domain.de"
      - "CMD_PROTOCOL_USESSL=true"
    ports:
      - "[::1]:8000:3000"
    volumes:
      - "/srv/hedgedoc/uploads:/hedgedoc/public/uploads"
```

```shell
# .postgres.env
POSTGRES_PASSWORD=S3cr3T
```

```shell
# .hedgedoc.env
CMD_DB_URL=postgres://hedgedoc:S3cr3T@postgres/hedgedoc
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:3000"
    ```

    ```nginx
    # /etc/nginx/sites-available/hedgedoc.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.27.3&config=modern&openssl=3.4.0&ocsp=false&guideline=5.7
    server {
        server_name hedgedoc.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/hedgedoc.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/hedgedoc.domain.de_ecc/hedgedoc.domain.de.key;
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
          - "traefik.http.services.srv_hedgedoc.loadbalancer.server.port=3000"
          - "traefik.http.routers.r_hedgedoc.rule=Host(`hedgedoc.domain.de`)"
          - "traefik.http.routers.r_hedgedoc.entrypoints=websecure"
    ```
