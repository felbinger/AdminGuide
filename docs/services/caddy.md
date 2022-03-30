# Caddy

```yaml
version: '3.9'

services:
    caddy:
        image: caddy
        restart: always
        ports:
            - "[::1]:80:80"
            - "[::1]:443:443"
        volumes:
            - "/srv/caddy/config:/etc/caddy"
```
Before starting this container you need to create the config file:
```bash
touch /srv/caddy/config/Caddyfile
```
