# MongoDB

MongoDB ist eine dokumentenorientierte NoSQL-Datenbank, die eine flexible und skalierbare Speicherlösung für
strukturierte und unstrukturierte Daten bietet.

```yaml
services:
  mongodb:
    image: mongo
    restart: always
    env_file: .mongodb.env
    ports:
      - "[::1]:27017:27017"
    volumes:
      - "/etc/localtime:/etc/localtime:ro"
      - "/srv/mongodb/data:/data/db"
```

```shell
# .mongodb.env
MONGO_INITDB_ROOT_USERNAME=root
MONGO_INITDB_ROOT_PASSWORD=S3cr3T
```