# pgAdmin 4

Eine webbasierte Datenbank Visualisierungs- und Bearbeitungssoftware.

```yaml
services:
  pgadmin:
    image: dpage/pgadmin4
    restart: always
    env_file: .pgadmin.env
    ports:
      - "[::1]:8000:80"
    volumes:
      - "/srv/pgadmin/servers.json:/pgadmin4/servers.json"
      - "/srv/pgadmin/storage:/var/lib/pgadmin/storage"
```

```shell
# .pgadmin.env
PGADMIN_DEFAULT_EMAIL=admin@domain.de
PGADMIN_DEFAULT_PASSWORD=S3cr3T
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:80"
    ```

    ```nginx
    # /etc/nginx/sites-available/pgadmin.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.27.3&config=modern&openssl=3.4.0&ocsp=false&guideline=5.7
    server {
        server_name pgadmin.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/pgadmin.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/pgadmin.domain.de_ecc/pgadmin.domain.de.key;
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
          - "traefik.http.services.srv_pgadmin.loadbalancer.server.port=80"
          - "traefik.http.routers.r_pgadmin.rule=Host(`pgadmin.domain.de`)"
          - "traefik.http.routers.r_pgadmin.entrypoints=websecure"
    ```

### Automatic Login
*Du musst die `.pgpass` Datei in `/srv/pgadmin/storage/admin_domain.tld/.pgpass` hinzufügen.*
Nicht vergessen die Berechtigungen zu ändern: `chown -R 5050:5050 /srv/pgadmin/`