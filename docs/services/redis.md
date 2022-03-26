# Redis

!!! warning ""
	This Admin Guide is being rewritten at the moment!



[redis documentation](https://hub.docker.com/_/redis)
```yaml
  redis:
    image: redis
    restart: always
    command: "redis-server --appendonly yes"
    volumes:
      - "/srv/redis:/data"
```