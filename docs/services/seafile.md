# Seafile

```yaml
version: '3.9'

services:
  mariadb:
    image: mariadb   
    restart: always
    env_file: .mariadb.env
    volumes:
      - "/srv/seafile/mariadb:/var/lib/mysql"

  memcached:
    image: memcached
    restart: always
    entrypoint: memcached -m 256

  seafile:
    image: seafileltd/seafile-mc  
    restart: always
    env_file: .seafile.env
    environment:
      - "DB_HOST=mariadb"
      - "TIME_ZONE=Europe/Berlin"
      - "SEAFILE_SERVER_LETSENCRYPT=false"
      - "SEAFILE_SERVER_HOSTNAME=seafile.domain.de"
    volumes:
      - "/srv/seafile/data:/shared"
    ports:
      - "[::1]:8000:80"
```

```shell
# .mariadb.env
MYSQL_ROOT_PASSWORD=S3cr3T
```

```shell
# .seafile.env
DB_ROOT_PASSWD=S3cr3T
SEAFILE_ADMIN_EMAIL=admin@domain.de
SEAFILE_ADMIN_PASSWORD=S3cr3T
```
