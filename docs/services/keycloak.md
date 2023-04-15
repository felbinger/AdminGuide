# Keycloak

```yaml
version: '3.9'

services:
  postgres:
    image: postgres
    restart: always
    env_file: .postgres.env
    environment:
      - "POSTGRES_USER=keycloak"
      - "POSTGRES_DB=keycloak"
    volumes:
      - "/srv/keycloak/postgres:/var/lib/postgresql/data"

  keycloak:
    image: ghcr.io/secshellnet/keycloak
    restart: always
    command: start
    env_file: .keycloak.env
    environment:
      - "KC_DB_URL_HOST=postgres"
      - "KC_DB_USERNAME=keycloak"
      - "KC_DB_URL_DATABASE=keycloak"
      - "KC_PROXY=edge"
      - "KC_HOSTNAME_STRICT=false"
    ports:
      - "[::1]:8000:8080"
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
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
          - "traefik.http.services.srv_keycloak.loadbalancer.server.port=8080"
          - "traefik.http.routers.r_keycloak.rule=Host(`keycloak.domain.de`)"
          - "traefik.http.routers.r_keycloak.entrypoints=websecure"
    ```

```shell
# .postgres.env
POSTGRES_PASSWORD=S3cr3T
```

```shell
# .keycloak.env
KC_DB_PASSWORD=S3cr3T
KEYCLOAK_ADMIN=kcadmin
KEYCLOAK_ADMIN_PASSWORD=S3cr3T
```

### Admin Interface

Das Administrative Webinterface zur Verwaltung der Realms möchte man 
für gewöhnlich nicht aus dem Internet erreichbar haben. Daher erstellen 
wir zwei Virtual Hosts, einen für Administrative Zwecke und einen für 
die normale Anmeldung, der auch aus dem Internet erreichbar ist.

=== "nginx"
    Der administrative Virtual Host erhält die folgende `location`:
    ```nginx
        # redirect to admin console
        location ~* ^(\/)$ {
            return 301 https://keycloak.domain.de/admin/master/console/;
        }
    ```

    Der öffentliche Virtual Host erhält die folgenden `location`'s:
    ```nginx
        # redirect to account login
        location ~* ^(\/)$ {
            return 301 https://id.secshell.net/realms/main/account/;
        }

        # do not allow keycloak admin from this domain
        location ~* (\/admin\/|\/realms\/master\/) {
            return 403;
        }
    ```
=== "Traefik"
    TODO
