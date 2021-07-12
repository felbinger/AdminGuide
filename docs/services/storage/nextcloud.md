# Nextcloud

```yaml
  nextcloud:
    image: nextcloud
    restart: always
    env_file: .nextcloud.env
    volumes:
      - "/srv/storage/nextcloud/webroot:/var/www/html/"
      - "/srv/storage/nextcloud/data:/var/www/html/data"
      - "/srv/storage/nextcloud/custom_apps:/var/www/html/custom_apps"
      - "/srv/storage/nextcloud/config:/var/www/html/config"
      - "/srv/storage/nextcloud/themes:/var/www/html/themes/"
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_nextcloud.loadbalancer.server.port=80"
      - "traefik.http.routers.r_nextcloud.rule=Host(`nextcloud.domain.de`)"
      - "traefik.http.routers.r_nextcloud.entrypoints=websecure"
      - "traefik.http.routers.r_nextcloud.tls=true"
      - "traefik.http.routers.r_nextcloud.tls.certresolver=myresolver"
    networks:
      - proxy
      - database
```

Don't forget to create the `.nextcloud.env` with your environment variables:
```
POSTGRES_HOST=postgres
POSTGRES_DB=nextcloud
POSTGRES_USER=nextcloud
POSTGRES_PASSWORD=S3cr3T
NEXTCLOUD_ADMIN_USER=S3cr3T
NEXTCLOUD_ADMIN_PASSWORD=S3cr3T
NEXTCLOUD_TRUSTED_DOMAINS=nextcloud.domain.de
REDIS_HOST=redis
```
You can also use mariadb, checkout the [official documentation](https://hub.docker.com/_/nextcloud).

## LDAP Authentication
After you logged in, you can active the ldap application.  
Afterwards you can configure your ldap connection in the settings.  
When you create a new user account in ldap, you need to sync the nextcloud users.
You can do this, by clicking on the "Verify settings and count users" button in the second tab (Users) of the ldap settings.
