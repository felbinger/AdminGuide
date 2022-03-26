# Nextcloud

```yaml
version: '3.9'

services:
  postgres:
    image: postgres
    restart: always
    env_file: .postgres.env
    volumes:
      - "/srv/nextcloud/postgres:/var/lib/postgresql/data"

  redis:
    image: redis
    restart: always

  nextcloud:
    image: nextcloud
    restart: always
    env_file: .nextcloud.env
    volumes:
      - "/srv/nextcloud/data:/var/www/html"
    ports:
      - "[::1]:8000:80"
```

```shell
# .postgres.env
POSTGRES_DB=nextcloud
POSTGRES_HOST_AUTH_METHOD=trust
```

```shell
# .nextcloud.env
POSTGRES_HOST=postgres
POSTGRES_DB=nextcloud
POSTGRES_USER=postgres
POSTGRES_PASSWORD=irrelevant
NEXTCLOUD_ADMIN_USER=S3cr3T
NEXTCLOUD_ADMIN_PASSWORD=S3cr3T
NEXTCLOUD_TRUSTED_DOMAINS=nextcloud.domain.de
REDIS_HOST=redis
```

## Open ID Connect
[janikvonrotz.ch/2020/10/20/openid-connect-with-nextcloud-and-keycloak/](https://janikvonrotz.ch/2020/10/20/openid-connect-with-nextcloud-and-keycloak/)
