# MariaDB

Einfache SQL basierte Datenbank. Nachfolger von MySQL.

```yaml
version: '3.9'

services:
  mariadb:
    image: mariadb
    restart: always
    env_file: .mariadb.env
    volumes:
      - "/srv/mariadb:/var/lib/mysql" 
```

```shell
# .mariadb.env
MYSQL_ROOT_PASSWORD=S3cr3T
```
