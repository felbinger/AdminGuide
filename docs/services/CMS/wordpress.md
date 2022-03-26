# Wordpress

```yaml
services:
  mysql:
    image: mysql
    restart: always
    volumes:
      - "/srv/wordpress/mysql:/var/lib/mysql"
    environment:
      - "MYSQL_DATABASE=wordpress"
      - "MYSQL_USER=wordpress"
      - "MYSQL_PASSWORD=S3cr3T"

  wordpress:
    image: wordpress
    restart: always
    volumes:
      - "/srv/wordpress/plugins:/var/www/html/wp-content/plugins"
      - "/srv/wordpress/themes:/var/www/html/wp-content/themes"
      - "/srv/wordpress/uploads:/var/www/html/wp-content/uploads"
    environment:
      - "WORDPRESS_DB_HOST=mysql:3306"
      - "WORDPRESS_DB_USER=wordpress"
      - "WORDPRESS_DB_PASSWORD=S3cr3T"
      - "WORDPRESS_DB_NAME=wordpress"
    ports:
      - "[::1]:8000:80"
```