# WordPress

```yaml
version: '3.9'

services:
  mysql:
    image: mysql
    restart: always
    env_file: .mysql.env
    volumes:
      - "/srv/wordpress/mysql:/var/lib/mysql"

  wordpress:
    image: wordpress
    restart: always
    env_file: .wordpress.env
    volumes:
      - "/srv/wordpress/plugins:/var/www/html/wp-content/plugins"
      - "/srv/wordpress/themes:/var/www/html/wp-content/themes"
      - "/srv/wordpress/uploads:/var/www/html/wp-content/uploads"
    ports:
      - "[::1]:8000:80"
```

```shell
# .mysql.env
MYSQL_USER=wordpress
MYSQL_PASSWORD=S3cr3T
MYSQL_DATABASE=wordpress
```

```shell
# .wordpress.env
WORDPRESS_DB_HOST=mysql:3306
WORDPRESS_DB_USER=wordpress
WORDPRESS_DB_PASSWORD=S3cr3T
WORDPRESS_DB_NAME=wordpress
```