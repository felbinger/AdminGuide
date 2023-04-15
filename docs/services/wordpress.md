# WordPress

```yaml
version: '3.9'

services:
  mysql:
    image: mysql
    restart: always
    env_file: .mysql.env
    environment:
      - "MYSQL_DATABASE=wordpress"
      - "MYSQL_USER=wordpress"
    volumes:
      - "/srv/wordpress/mysql:/var/lib/mysql"

  wordpress:
    image: wordpress
    restart: always
    env_file: .wordpress.env
    environment:
      - "WORDPRESS_DB_HOST=mysql:3306"
      - "WORDPRESS_DB_USER=wordpress"
      - "WORDPRESS_DB_NAME=wordpress"
    volumes:
      - "/srv/wordpress/plugins:/var/www/html/wp-content/plugins"
      - "/srv/wordpress/themes:/var/www/html/wp-content/themes"
      - "/srv/wordpress/uploads:/var/www/html/wp-content/uploads"
    ports:
      - "[::1]:8000:80"
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:80"
    ```
=== "Traefik"
    ```yaml
        labels:
          - "traefik.enable=true"
          - "traefik.http.services.srv_wordpress.loadbalancer.server.port=80"
          - "traefik.http.routers.r_wordpress.rule=Host(`wordpress.domain.de`)"
          - "traefik.http.routers.r_wordpress.entrypoints=websecure"
    ```

```shell
# .mysql.env
MYSQL_PASSWORD=S3cr3T
```

```shell
# .wordpress.env
WORDPRESS_DB_PASSWORD=S3cr3T
```