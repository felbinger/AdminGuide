# Guacamole

```yaml
version: '3.9'

services:
  postgres:
    image: postgres
    restart: always
    env_file: .postgres.env
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
    env_file: .guacamole.env
    ports:
      - "[::1]:8000:8080"
```

```shell
# .postgres.env
POSTGRES_HOST_AUTH_METHOD=trust
POSTGRES_USER=guacamole
POSTGRES_DB=guacamole
```

```shell
# .guacamole.env
GUACD_HOSTNAME=guacd
POSTGRES_HOSTNAME=postgres
POSTGRES_DATABASE=guacamole 
POSTGRES_USER=guacamole  
POSTGRES_PASSWORD=none
TOTP_ENABLED=true
```