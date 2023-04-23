# Guacamole

Guacamole ist ein Webanwendungsdienst, welcher es ermöglicht, über einen Webbrowser auf entfernte Computer oder Server
zuzugreifen, ohne dass spezielle Client-Software installiert werden muss.

```yaml
version: '3.9'

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
      - "POSTGRES_HOSTNAME=postgres"
      - "POSTGRES_USER=guacamole"
      - "POSTGRES_DATABASE=guacamole"
      #- "TOTP_ENABLED=true"
    ports:
      - "[::1]:8000:8080"
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:8080"
    ```
=== "Traefik"
    ```yaml
        labels:
          - "traefik.enable=true"
          - "traefik.http.services.srv_guacamole.loadbalancer.server.port=8080"
          - "traefik.http.routers.r_guacamole.rule=Host(`guacamole.domain.de`)"
          - "traefik.http.routers.r_guacamole.entrypoints=websecure"
    ```

```shell
# .postgres.env
POSTGRES_PASSWORD=S3cr3T
```

```shell
# .guacamole.env
POSTGRES_PASSWORD=S3cr3T
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
