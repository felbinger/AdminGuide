## MongoDB
Checkout the [documentation](https://hub.docker.com/_/mongo)
```yaml
  mongodb:
    image: mongo
    restart: always
    environment:
      - "MONGO_INITDB_ROOT_USERNAME=root"
      - "MONGO_INITDB_ROOT_PASSWORD=S3cr3T"
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "/srv/main/mongodb/transfer:/data/transfer"
      - "/srv/main/mongodb/data:/data/db"
    networks:
      - database
```