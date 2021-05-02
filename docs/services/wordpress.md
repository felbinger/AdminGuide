```yaml
services:
  mysql:
    image: mysql
    volumes:
      - /srv/comms/wordpress/:/var/lib/mysql
    restart: always
    environment:    
      MYSQL_DATABASE: wordpress
      MYSQL_USER: wordpress
      MYSQL_PASSWORD: S3cr3T
    networks:
      - database

  wordpress:
    depends_on:
      - mysql
    image: wordpress
    restart: always
    environment:
      WORDPRESS_DB_HOST: mysql:3306
      WORDPRESS_DB_USER: wordpress
      WORDPRESS_DB_PASSWORD: S3cr3T
      WORDPRESS_DB_NAME: wordpress
    labels:
     - "traefik.enable=true"
      - "traefik.http.services.srv_wordpress.loadbalancer.server.port=80"
      - "traefik.http.routers.r_wordpress.rule=Host(`wordpress.domain.de`)"
      - "traefik.http.routers.r_wordpress.entrypoints=websecure"
      - "traefik.http.routers.r_wordpress.tls=true"
      - "traefik.http.routers.r_wordpress.tls.certresolver=myresolver"
    networks:
      - database
      - proxy
```