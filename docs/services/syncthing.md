# Syncthing

```yml
version: '3.9'

services:
  syncthing:
    image: syncthing/syncthing
    restart: always
    volumes:
      - "/srv/syncthing:/var/syncthing"
    ports:
      - "22000:22000"
      - "[::1]:8000:8384"
```