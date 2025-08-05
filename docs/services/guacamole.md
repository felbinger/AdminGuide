# Guacamole

Guacamole ist ein Webanwendungsdienst, welcher es ermöglicht, über einen Webbrowser auf entfernte Computer oder Server
zuzugreifen, ohne dass spezielle Client-Software installiert werden muss.

```yaml
services:
  postgres:
    image: postgres
    restart: always
    env_file: .postgres.env
    environment:
      - "POSTGRES_DB=guacamole"
      - "POSTGRES_USER=guacamole"
    volumes:
      - "/srv/guacamole/postgres:/var/lib/postgresql/data"

  guacd:
    image: guacamole/guacd
    restart: always
    volumes:
      - "/srv/guacamole/share:/share"

  guacamole:
    image: guacamole/guacamole
    restart: always
    env_file: .guacamole.env
    environment:
      - "GUACD_HOSTNAME=guacd"
      - "POSTGRESQL_HOSTNAME=postgres"
      - "POSTGRESQL_USER=guacamole"
      - "POSTGRESQL_DATABASE=guacamole"
      #- "TOTP_ENABLED=true"
    ports:
      - "[::1]:8000:8080"
```

```shell
# .postgres.env
POSTGRES_PASSWORD=S3cr3T
```

```shell
# .guacamole.env
POSTGRESQL_PASSWORD=S3cr3T
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:8080"
    ```

    ```nginx
    # /etc/nginx/sites-available/guacamole.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.27.3&config=modern&openssl=3.4.0&ocsp=false&guideline=5.7
    server {
        server_name guacamole.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/guacamole.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/guacamole.domain.de_ecc/guacamole.domain.de.key;
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
            proxy_pass http://[::1]:8000/guacamole/;
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
          - "traefik.http.services.srv_guacamole.loadbalancer.server.port=8080"
          - "traefik.http.routers.r_guacamole.rule=Host(`guacamole.domain.de`)"
          - "traefik.http.routers.r_guacamole.entrypoints=websecure"

          - "traefik.http.middlewares.guacprefix.addprefix.prefix=/guacamole"
          - "traefik.http.routers.r_guacamole.middlewares=guacprefix"
    ```

## OpenID Connect / Keycloak
```shell
# extend .guacamole.env
OPENID_AUTHORIZATION_ENDPOINT=https://id.domain.de/realms/<realm>/protocol/openid-connect/auth
OPENID_JWKS_ENDPOINT=https://id.domain.de/realms/<realm>/protocol/openid-connect/certs
OPENID_ISSUER=https://id.domain.de/realms/<realm>
OPENID_CLIENT_ID=guacamole.domain.de
OPENID_REDIRECT_URI=https://guacamole.domain.de/
OPENID_CLAIM_TYPE=sub
OPENID_CLAIM_TYPE=preferred_username
OPENID_SCOPE=openid profile

# "hide" java user agent by prepending "irrelevant"
JAVA_OPTS=-Dhttp.agent=irrelevant
```

Um einen neuen OIDC Client in Keycloak hinzuzufügen:
- Standard Flow Enabled: off
- Implicit Flow Enabled: on
