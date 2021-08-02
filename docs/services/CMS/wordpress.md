# Wordpress

```yaml
services:
  mysql:
    image: mysql
    restart: always
    volumes:
      - "/srv/comms/wordpress/mysql:/var/lib/mysql"
    environment:
      - "MYSQL_DATABASE=wordpress"
      - "MYSQL_USER=wordpress"
      - "MYSQL_PASSWORD=S3cr3T"
    networks:
      - database

  wordpress:
    image: wordpress
    restart: always
    volumes:
      - "/srv/comms/wordpress/plugins:/var/www/html/wp-content/plugins"
      - "/srv/comms/wordpress/themes:/var/www/html/wp-content/themes"
      - "/srv/comms/wordpress/uploads:/var/www/html/wp-content/uploads"
    environment:
      - "WORDPRESS_DB_HOST=mysql:3306"
      - "WORDPRESS_DB_USER=wordpress"
      - "WORDPRESS_DB_PASSWORD=S3cr3T"
      - "WORDPRESS_DB_NAME=wordpress"
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