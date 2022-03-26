# Guacamole

```
version: '3.9'

services:
  postgres:
    image: postgres
    restart: always
    environment:
      - "POSTGRES_HOST_AUTH_METHOD=trust"
      - "POSTGRES_USER=guacamole_user"
      - "POSTGRES_DB=guacamole_db"
    volumes:
      - "/srv/guacamole/postgres:/var/lib/postgresql/data"

  guacd:
    image: guacamole/guacd
    restart: always
    volumes:
      - "/srv/guacamole/share:/share"

  guacamole:
    image: guacamole/guacamole
    restart: always
    environment:
      - "GUACD_HOSTNAME=guacd"
      - "POSTGRES_HOSTNAME=postgres"
      - "POSTGRES_DATABASE=guacamole_db" 
      - "POSTGRES_USER=guacamole_user"  
      - "POSTGRES_PASSWORD=none"
    #  - "TOTP_ENABLED=true"
    ports:
      - "[::1]:8000:8080"
```