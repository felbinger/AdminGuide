# MariaDB

!!! warning ""
	This Admin Guide is being rewritten at the moment!



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
      - "/srv/mariadb/data:/var/lib/mysql"

  phpmyadmin:
    image: phpmyadmin
    restart: "no"
    environment:
      - "PMA_HOST=mariadb"
      - "PMA_PORT=3306"
      - "PMA_ABSOLUTE_URI=https://phpmyadmin.domain.tld/"
      - "UPLOAD_LIMIT=512M"
      - "HIDE_PHP_VERSION=true"
    ports:
      - "[::1]:8000:80"
```
