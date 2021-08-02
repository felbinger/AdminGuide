# Seafile

```yaml
  mariadb:
    image: mariadb   
    restart: always
    environment:
      - "MYSQL_ROOT_PASSWORD=S3cr3T"
      - "MYSQL_LOG_CONSOLE=true"
    volumes:
      - "/srv/storage/seafile/mysql:/var/lib/mysql"
    networks:
      - database

  memcached:
    image: memcached
    restart: always
    entrypoint: memcached -m 256
    networks:
      - database

  seafile:
    image: seafileltd/seafile-mc:latest  
    restart: always
    volumes:
      - "/srv/storage/seafile/data:/shared"
    environment:
      - "DB_HOST=mariadb"
      - "DB_ROOT_PASSWD=S3cr3T"
      - "TIME_ZONE=Europe/Berlin"
      - "SEAFILE_ADMIN_EMAIL=admin@domain.de"
      - "SEAFILE_ADMIN_PASSWORD=S3cr3T"
      - "SEAFILE_SERVER_LETSENCRYPT=false"
      - "SEAFILE_SERVER_HOSTNAME=seafile.domain.de"
    labels:     
      - "traefik.enable=true"
      - "traefik.http.services.srv_seafile.loadbalancer.server.port=80"
      - "traefik.http.routers.r_seafile.rule=Host(`seafile.domain.de`)"
      - "traefik.http.routers.r_seafile.entrypoints=websecure"
    networks:
      - database
      - proxy
```

Unfortunately, Seafile requires root access for the database. Therefore, you should create your own database for Seafile. 
