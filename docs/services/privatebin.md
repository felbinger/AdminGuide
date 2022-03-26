# Privatebin

```yaml
version: '3.9'
services:
  privatebin:
    image: privatebin/nginx-fpm-alpine
    restart: always
    ports:
      - "[::1]:8000:8080"
    volumes:
      - "/srv/privatebin:/srv/data"
```