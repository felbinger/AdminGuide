# Calibre

```yaml
version: '3.9'

services:
  calibre:
    image: linuxserver/calibre-web
    restart: always
    env_file: .calibre.env
    ports:
      - "[::1]:8000:8083"
    volumes:
      - "/srv/calibre/config:/config"
      - "/srv/calibre/books:/books"
```

```shell
# .calibre.env
PUID=1000
PGID=1000
SET_CONTAINER_TIMEZONE=true
CONTAINER_TIMEZONE=Europe/Berlin
USE_CONFIG_DIR=true
```