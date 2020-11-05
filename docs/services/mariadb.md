## MariaDB
Checkout the [documentation](https://hub.docker.com/_/mariadb/)
```yml
  mariadb:
    image: mariadb
    restart: always
    environment:
      - "MYSQL_ROOT_PASSWORD=S3cr3T"
    volumes:
      - "/srv/main/mariadb/data:/var/lib/mysql"
    networks:
      - database
```

## PHPmyAdmin
Checkout the [documentation](https://hub.docker.com/_/phpmyadmin)
```yml
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
