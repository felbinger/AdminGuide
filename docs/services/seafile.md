```yaml
  mariadb:
    image: mariadb:10.1   
    restart: unless-stopped
    environment:
      - MYSQL_ROOT_PASSWORD=S3cr3T
      - MYSQL_LOG_CONSOLE=true
    volumes:
      - /srv/storage/seafile/data:/var/lib/mysql
    networks:
      - database
  memcached:
    image: memcached:1.5.6   
    restart: unless-stopped
    entrypoint: memcached -m 256
    networks:
      - database
  seafile:
    image: seafileltd/seafile-mc:latest  
    restart: unless-stopped
    volumes:
      - /srv/storage/shared:/shared
    environment:
      - DB_HOST=mariadb
      - DB_ROOT_PASSWD=S3cr3T
      - TIME_ZONE=Europe/Berlin
      - SEAFILE_ADMIN_EMAIL=admin@domain.tld
      - SEAFILE_ADMIN_PASSWORD=S3cr3T
      - SEAFILE_SERVER_LETSENCRYPT=false
      - SEAFILE_SERVER_HOSTNAME=cloud.domain.de
    labels:     
      - "traefik.enable=true"
      - "traefik.http.services.srv_seafile.loadbalancer.server.port=80"
      - "traefik.http.routers.r_seafile.rule=Host(`cloud.domain.de`)"
      - "traefik.http.routers.r_seafile.entrypoints=websecure"
      - "traefik.http.routers.r_seafile.tls=true"
      - "traefik.http.routers.r_seafile.tls.certresolver=myresolver"
    depends_on:
      - mariadb
      - memcached
    networks:
      - database
      - proxy
```

At the current time, I unfortunately only have the info that you have to set the MYSQL_ROOT_PASSWORD. If you share the database with several services, I do not recommend using Seafile for security reasons. 