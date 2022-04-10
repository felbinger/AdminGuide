# Guacamole

```yaml
version: '3.9'

services:
  postgres:
    image: postgres
    restart: always
    env_file: .postgres.env
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
    ports:
      - "[::1]:8000:8080"
```

```shell
# .postgres.env
POSTGRES_HOST_AUTH_METHOD=trust
POSTGRES_USER=guacamole
POSTGRES_DB=guacamole
```

```shell
# .guacamole.env
GUACD_HOSTNAME=guacd
POSTGRES_HOSTNAME=postgres
POSTGRES_DATABASE=guacamole 
POSTGRES_USER=guacamole  
POSTGRES_PASSWORD=none
#TOTP_ENABLED=true
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

Add a new OIDC client in Keycloak:  
- Standard Flow Enabled: off
- Implicit Flow Enabled: on
