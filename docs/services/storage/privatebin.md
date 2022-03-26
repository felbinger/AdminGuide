# Privatebin

```yaml
  privatebin:
    image: privatebin/nginx-fpm-alpine:latest
    restart: always
    ports:
      - "[::1]:8000:8080"
    volumes:
      - "/srv/privatebin/data:/srv/data"
```