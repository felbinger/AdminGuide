# HedgeDoc

HedgeDoc ist eine Open-Source-Plattform für die kollaborative Bearbeitung von Dokumenten in Echtzeit, ähnlich wie Google
Docs oder Microsoft Office Online.

```yaml
version: '3.9'

services:
  postgres:
    image: postgres
    restart: always
    env_file: .postgres.env
    environment:
      - "POSTGRES_DB=hedgedoc"
      - "POSTGRES_USER=hedgedoc"
    volumes:
      - "/srv/hedgedoc/postgres:/var/lib/postgresql/data"

  hedgedoc:
    image: quay.io/hedgedoc/hedgedoc
    restart: always
    env_file: .hedgedoc.env
    environment:
      - "CMD_DOMAIN=hedgedoc.domain.de"
      - "CMD_PROTOCOL_USESSL=true"
    ports:
      - "[::1]:8000:3000"
    volumes:
      - "/srv/hedgedoc/uploads:/hedgedoc/public/uploads"
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:3000"
    ```
=== "Traefik"
    ```yaml
        labels:
          - "traefik.enable=true"
          - "traefik.http.services.srv_hedgedoc.loadbalancer.server.port=3000"
          - "traefik.http.routers.r_hedgedoc.rule=Host(`hedgedoc.domain.de`)"
          - "traefik.http.routers.r_hedgedoc.entrypoints=websecure"
    ```

```shell
# .postgres.env
POSTGRES_PASSWORD=S3cr3T
```

```shell
# .hedgedoc.env
CMD_DB_URL=postgres://hedgedoc:S3cr3T@postgres/hedgedoc
```