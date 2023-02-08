# HedgeDoc

```yaml
version: '3.9'

services:
  postgres:
    image: postgres
    restart: always
    env_file: .postgres.env
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

```shell
# .postgres.env
POSTGRES_HOST_AUTH_METHOD=trust
POSTGRES_USER=hedgedoc
POSTGRES_DB=hedgedoc
```

```shell
# .hedgedoc.env
CMD_DB_URL=postgres://hedgedoc@postgres/hedgedoc
```