# pgAdmin 4

```yaml
version: '3.9'
	
services:
  pgadmin:
    image: dpage/pgadmin4
    restart: always
    env_file: .pgadmin.env
    ports:
      - "[::1]:8000:80"
    volumes:
      - "/srv/pgadmin/servers.json:/pgadmin4/servers.json"
      - "/srv/pgadmin/storage:/var/lib/pgadmin/storage"
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:80"
    ```
=== "Traefik"
    ```yaml
        labels:
          - "traefik.enable=true"
          - "traefik.http.services.srv_pgadmin.loadbalancer.server.port=80"
          - "traefik.http.routers.r_pgadmin.rule=Host(`pgadmin.domain.de`)"
          - "traefik.http.routers.r_pgadmin.entrypoints=websecure"
    ```

```shell
# .pgadmin.env
PGADMIN_DEFAULT_EMAIL=admin@domain.de
PGADMIN_DEFAULT_PASSWORD=S3cr3T
```

### Automatic Login
* You need to add the `.pgpass` file to `/srv/main/pgadmin/storage/admin_domain.tld/.pgpass`.  
Don't forget to adjust the permissions: `chown -R 5050:5050 /srv/main/pgadmin/`
