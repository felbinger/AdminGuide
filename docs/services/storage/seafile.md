# Seafile

```yaml
  mariadb:
    image: mariadb   
    restart: always
    environment:
      - "MYSQL_ROOT_PASSWORD=S3cr3T"
      - "MYSQL_LOG_CONSOLE=true"
    volumes:
      - "/srv/seafile/mysql:/var/lib/mysql"

  memcached:
    image: memcached
    restart: always
    entrypoint: memcached -m 256

  seafile:
    image: seafileltd/seafile-mc:latest  
    restart: always
    volumes:
      - "/srv/seafile/data:/shared"
    environment:
      - "DB_HOST=mariadb"
      - "DB_ROOT_PASSWD=S3cr3T"
      - "TIME_ZONE=Europe/Berlin"
      - "SEAFILE_ADMIN_EMAIL=admin@domain.de"
      - "SEAFILE_ADMIN_PASSWORD=S3cr3T"
      - "SEAFILE_SERVER_LETSENCRYPT=false"
      - "SEAFILE_SERVER_HOSTNAME=seafile.domain.de"
    ports:
      - "[::1]:8000:80"
```

Unfortunately, Seafile requires root access for the database. Therefore, you should create your own database for Seafile. 
