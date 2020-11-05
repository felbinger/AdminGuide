[redis documentation](https://hub.docker.com/_/redis)
```yaml
  redis:
    image: redis
    restart: always
    command: "redis-server --appendonly yes"
    volumes:
      - "/srv/main/redis:/data"
    networks:
      - database
```