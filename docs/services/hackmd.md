# HackMD

```yaml
version: '3.9'

services:
  mariadb:
    image: mariadb   
    restart: always
    env_file: .mariadb.env
    volumes:
      - "/srv/hackmd/mariadb:/var/lib/mysql"
	
  hackmd:
    image: hackmdio/hackmd
    restart: always
    env_file: .hackmd.env
    ports:
      - "[::1]:8000:3000"
```

```shell
# .mariadb.env
MYSQL_RANDOM_ROOT_PASSWORD=yes
MYSQL_USER=hackmd
MYSQL_PASSWORD=S3cr3T
MYSQL_DATABASE=hackmd
```

```shell
# .hackmd.env
CMD_DB_URL=mysql://hackmd:S3cr3T@mariadb/hackmd
```