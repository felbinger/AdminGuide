# PostgreSQL

Eine SQL basierte relationale Datenbank.

```yaml
version: '3.9'

services:
  postgres:
    image: postgres
    restart: always
    env_file: .postgres.env
    environment:
      - "POSTGRES_USER=postgres"
    volumes:
      - "/srv/postgres:/var/lib/postgresql/data"
```

```shell
# .postgres.env
POSTGRES_PASSWORD=S3cr3T
```