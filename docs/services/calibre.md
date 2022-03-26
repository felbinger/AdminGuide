# Calibre

!!! warning ""
	This Admin Guide is being rewritten at the moment!



```yaml
  calibre:
    image: linuxserver/calibre-web
    restart: always
    environment:
      - "PUID=1000"
      - "PGID=1000"
      - "SET_CONTAINER_TIMEZONE=true"
      - "CONTAINER_TIMEZONE=Europe/Berlin"
      - "USE_CONFIG_DIR=true"
    ports:
      - "[::1]:8000:8083"
    volumes:
      - "/srv/calibre/config:/config"
      - "/srv/calibre/books:/books"
```