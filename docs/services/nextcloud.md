# Nextcloud

```yaml
version: '3.9'

services:
  postgres:
    image: postgres
    restart: always
    env_file: .postgres.env
    environment:
      - "POSTGRES_DB=nextcloud"
      - "POSTGRES_USER=nextcloud"
    volumes:
      - "/srv/nextcloud/postgres:/var/lib/postgresql/data"

  redis:
    image: redis
    restart: always

  nextcloud:
    image: nextcloud
    restart: always
    env_file: .nextcloud.env
    environment:
      - "POSTGRES_HOST=postgres"
      - "POSTGRES_DB=nextcloud"
      - "POSTGRES_USER=nextcloud"
      - "NEXTCLOUD_TRUSTED_DOMAINS=nextcloud.domain.de"
      - "REDIS_HOST=redis"
    volumes:
      - "/srv/nextcloud/data:/var/www/html"
    ports:
      - "[::1]:8000:80"
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:80"
    ```
=== "Traefik"
    ```yaml
        labels:
          - "traefik.enable=true"
          - "traefik.http.services.srv_nextcloud.loadbalancer.server.port=80"
          - "traefik.http.routers.r_nextcloud.rule=Host(`nextcloud.domain.de`)"
          - "traefik.http.routers.r_nextcloud.entrypoints=websecure"
    ```

```shell
# .postgres.env
POSTGRES_PASSWORD=S3cr3T
```

```shell
# .nextcloud.env
POSTGRES_PASSWORD=S3cr3T
NEXTCLOUD_ADMIN_USER=username
NEXTCLOUD_ADMIN_PASSWORD=p4ssw0rd
```

## Open ID Connect
[janikvonrotz.ch/2020/10/20/openid-connect-with-nextcloud-and-keycloak/](https://janikvonrotz.ch/2020/10/20/openid-connect-with-nextcloud-and-keycloak/)
