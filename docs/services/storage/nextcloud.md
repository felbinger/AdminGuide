# Nextcloud

```yaml
  postgres:
    image: postgres
    restart: always
    environment:
      - "POSTGRES_DB=nextcloud"
      - "POSTGRES_HOST_AUTH_METHOD=trust"
    volumes:
      - "/srv/nextcloud/postgres:/var/lib/postgresql/data"

  redis:
    image: redis
    restart: always

  nextcloud:
    image: nextcloud
    restart: always
    environment:
      - "POSTGRES_HOST=postgres"
      - "POSTGRES_DB=nextcloud"
      - "POSTGRES_USER=postgres"
      - "POSTGRES_PASSWORD=irrelevant"
      - "NEXTCLOUD_ADMIN_USER=S3cr3T"
      - "NEXTCLOUD_ADMIN_PASSWORD=S3cr3T"
      - "NEXTCLOUD_TRUSTED_DOMAINS=nextcloud.domain.de"
      - "REDIS_HOST=redis"
    volumes:
      - "/srv/nextcloud/data:/var/www/html"
    ports:
      - "[::1]:8000:80"
```

## LDAP Authentication
After you logged in, you can active the ldap application.  
Afterwards you can configure your ldap connection in the settings.  
When you create a new user account in ldap, you need to sync the nextcloud users.
You can do this, by clicking on the "Verify settings and count users" button in the second tab (Users) of the ldap settings.

## Open ID Connect
TODO
