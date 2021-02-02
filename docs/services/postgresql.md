## PostgreSQL
[postgres documentation](https://hub.docker.com/_/postgres)

You can generate a database by setting the commented out environment variables.
```yaml
  postgresql:
    image: postgres
    restart: always
    environment:
      - "POSTGRES_PASSWORD=S3cr3T"
      #- "POSTGRES_DB=app"
    volumes:
      - "/srv/main/postgres/transfer:/transfer"
      - "/srv/main/postgres/data:/var/lib/postgresql/data"
    networks:
      - database
```

## pgAdmin 4
```yaml
  pgadmin:
    image: dpage/pgadmin4
    restart: always
    environment:
      - "PGADMIN_DEFAULT_EMAIL=admin@domain.tld"
      - "PGADMIN_DEFAULT_PASSWORD=S3cr3T"
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_pgadmin.loadbalancer.server.port=80"
      - "traefik.http.routers.r_pgadmin.rule=Host(`pgadmin.domain.de`)"
      - "traefik.http.routers.r_pgadmin.entrypoints=websecure"
      - "traefik.http.routers.r_pgadmin.tls=true"
      - "traefik.http.routers.r_pgadmin.tls.certresolver=myresolver"
    volumes:
      - "/srv/main/pgadmin/servers.json:/pgadmin4/servers.json"
      - "/srv/main/pgadmin/storage:/var/lib/pgadmin/storage"
    networks:
      - database
      - proxy
```

### Automatic Login
* You need to add the `.pgpass` file to `/srv/main/pgadmin/storage/admin_domain.tld/.pgpass`.  
Don't forget to adjust the permissions: `chown -R 5050:5050 /srv/main/pgadmin/`
