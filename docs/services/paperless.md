# paperless

```yaml
version: '3.9'
	
services:
  broker:
    image: docker.io/library/redis:7
    restart: unless-stopped

  postgres:
    image: docker.io/library/postgres:15
    restart: unless-stopped
    env_file: .postgres.env
    environment:
      - "POSTGRES_DB=paperless"
    volumes:
      - "/srv/paperless/postgres:/var/lib/postgresql/data"

  gotenberg:
    image: docker.io/thecodingmachine/gotenberg:7.8
    restart: unless-stopped
    # The gotenberg chromium route is used to convert .eml files. We do not
    # want to allow external content like tracking pixels or even javascript.
    command:
      - "gotenberg"
      - "--chromium-disable-javascript=true"
      - "--chromium-allow-list=file:///tmp/.*"

  tika:
    image: ghcr.io/paperless-ngx/tika:latest
    restart: unless-stopped

  webserver:
    image: ghcr.io/paperless-ngx/paperless-ngx:latest
    restart: unless-stopped
    depends_on:
      - "broker"
      - "postgres"
      - "gotenberg"
      - "tika"
    ports:
      - "[::1]:8000:8000"
    healthcheck:
      test: ["CMD", "curl", "-fs", "-S", "--max-time", "2", "http://localhost:8000"]
      interval: 30s
      timeout: 10s
      retries: 5
    volumes:
      - "/srv/paperless/data:/usr/src/paperless/data"
      - "/srv/paperless/media:/usr/src/paperless/media"
      - "/srv/paperless/export:/usr/src/paperless/export"
      - "/srv/paperless/consume:/usr/src/paperless/consume"
    env_file: .paperless.env
    environment:
      - "PAPERLESS_REDIS=redis://broker:6379"
      - "PAPERLESS_DBHOST=postgres"
      - "PAPERLESS_TIKA_ENABLED=1"
      - "PAPERLESS_TIKA_GOTENBERG_ENDPOINT=http://gotenberg:3000"
      - "PAPERLESS_TIKA_ENDPOINT=http://tika:9998"
      - "PAPERLESS_TIME_ZONE=Europe/Berlin"
      - "PAPERLESS_OCR_LANGUAGE=deu"
      - "PAPERLESS_URL=https://paperless.domain.de"
```

```shell
# .postgres.env
POSTGRES_USER=paperless
POSTGRES_PASSWORD=S3cr3t-P4ssw0rd
```

```shell
# .paperless.env
PAPERLESS_DBUSER=paperless
PAPERLESS_DBPASS=S3cr3t-P4ssw0rd
```

## Create user
```shell
docker compose run --rm webserver createsuperuser
```

## Open ID Connect
Not until [github.com/paperless-ngx/paperless-ngx/pull/1746](https://github.com/paperless-ngx/paperless-ngx/pull/1746) has been merged.
