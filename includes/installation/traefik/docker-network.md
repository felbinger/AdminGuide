Anschließend legen wir das `proxy` Docker Netzwerk an und starten Traefik.
```shell
docker network create proxy
docker compose up -d
```