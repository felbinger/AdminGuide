# MariaDB

[phpmyadmin documentation](https://hub.docker.com/_/phpmyadmin)    
[mariadb documentation](https://hub.docker.com/_/mariadb/)  

You can generate a database and/or a user account which has full access on this database by setting the commented out environment variables.
```yaml
  mariadb:
    image: mariadb
    restart: always
    environment:
      - "MYSQL_ROOT_PASSWORD=S3cr3T"
      #- "MYSQL_DATABASE=app"
      #- "MYSQL_USER=app"
      #- "MYSQL_PASSWORD=S3cr3T"
    volumes:
      - "/srv/main/mariadb/data:/var/lib/mysql"
    networks:
      - database

  phpmyadmin:
    image: phpmyadmin
    restart: "no"
    environment:
      - "PMA_HOST=mariadb"
      - "PMA_PORT=3306"
      - "PMA_ABSOLUTE_URI=https://phpmyadmin.domain.tld/"
      - "UPLOAD_LIMIT=512M"
      - "HIDE_PHP_VERSION=true"
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_phpmyadmin.loadbalancer.server.port=80"
      - "traefik.http.routers.r_phpmyadmin.rule=Host(`phpmyadmin.domain.de`)"
      - "traefik.http.routers.r_phpmyadmin.entrypoints=websecure"
      - "traefik.http.routers.r_phpmyadmin.tls=true"
      - "traefik.http.routers.r_phpmyadmin.tls.certresolver=myresolver"
    networks:
      - proxy
      - database
```
