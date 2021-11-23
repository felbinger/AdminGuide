# Matrix

First add this configuration to your `docker-compose.yml`
```yaml
  matrix:
    image: matrixdotorg/synapse
    restart: always
    volumes:
      - "/srv/comms/synapse:/data"
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_homepage.loadbalancer.server.port=8008"
      - "traefik.http.routers.r_matrix.rule=Host(`matrix.domain.de`)"
      - "traefik.http.routers.r_matrix.entrypoints=websecure"
      - "traefik.http.routers.r_matrix.tls=true"
      - "traefik.http.routers.r_matrix.tls.certresolver=myresolver"
    networks:
      - proxy
      - database
```
Before starting this container you need to generate a configuration file. This command generates a `homeserver.yaml` configuartion file under /srv/comms/synapse
```yaml
docker run -it --rm -v "/srv/comms/synapse:/data" -e "SYNAPSE_SERVER_NAME=matrix.domain.de" -e "SYNAPSE_REPORT_STATS=no" matrixdotorg/synapse:latest generate
```
You have to specify the domain of the service using the `SYNAPSE_SERVER_NAME` environment variable. You also can enable anonymous statistics reporting by setting sthe `SYNAPSE_REPORT_STATS` to yes.

After the command is done you can find the homeserver.yaml configurationfile in the data folder. 
Now you can start the service using `docker-compose up -d matrix`.

### Register a new user 
If you want to enable registration via Matrix clients such as element you can enable it in your `homeserver.yaml` file.
```yaml
...
enable_registration: true
...
```

Don't forget to start the container after editing the option with `docker-compose up -d`

You can also create a new user from the command line:
```yaml
docker-compose exec matrix register_new_matrix_user -u USERNAME -p PASSWORD -a -c /data/homeserver.yaml https://matrix.domain.de
```

### Using Postgres

For using postgresql append this configuration to your docker-compose

``` yaml
  postgres:
    image: postgres
    restart: always
    environment:
      - "POSTGRES_PASSWORD=S3cr3T"
      - "POSTGRES_DB=synapse"
      - "POSTGRES_INITDB_ARGS=-E UTF8 --lc-collate=C --lc-ctype=C"
    volumes:
      - "/srv/main/postgres/transfer:/transfer"
      - "/srv/main/postgres/data:/var/lib/postgresql/data"
    networks:
      - database
```

Now you have to edit the `homeserver.yaml`. Go to the Database section and uncomment it and add your postgresql settings. 

``` yaml
database:
  name: psycopg2
  args:
    user: postgres
    password: secret
    database: synapse
    host: postgres
    cp_min: 5
    cp_max: 10
```

By default, a SQLite database is used, so we still need to comment it out.


``` yaml
#database:
# name: sqlite3
# args:
# database: /data/homeserver.db

```

Now you are finish and you can start the container with `docker-compose up -d`

### Reset password of user 

If you want to reset the password run 
```shell
docker-compose exec -u www-data matrix hash_password -p PASSWORD
```

After the command is done you will get a password hash as stdout. 

Once you have generated the password hash you can update the value in the database. First start a shell in the postgress container with. 
```shell
docker-compose exec postgres /bin/bash
```
Next, you can update the password with the command 
```shell
PGPASSWORD=S3cr3T \
  psql -U postgres -d synapse -c \
  "UPDATE users SET password_hash='\$2a\$12$xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx' \
  WHERE name='@test:test.com';"
```

### Federation 

To enable cross-server communication you need to set an SRV DNS record.

```
;; SRV Records
_matrix._tcp.matrix.domain.de.    1    IN    SRV    10 5 443 matrix.domain.de.
```

![DNS configuration](../../img/services/matrix-dns.jpg){: loading=lazy }


Note You can also host your own Matrix WebClient. [Host your own Matrix WebClient ](./element.md)

### SSO with Keycloak

If you have an Instance of *Keycloak* running, you can use it as an external Authentication Provider.
At first, we have to create the Client in Keycloak. Create a new Client. Use `matrix.domain.de` as Client ID
and `openid` as Protocol. Edit your newly created Client as follows:

Setting | Value
--------|-------
Access Type | confidential
Direct Access Grants Enabled | OFF
Root URL | `https://matrix.domain.de`
Valid Redirect URIs | `https://matrix.domain.de` <br /> `http://matrix.domain.de`
Base URL | `https://matrix.domain.de`
Web Origins | +

Now go to the "Credentials" Tab and save the Client Secret; we will need it later.

<br />

Now we have to edit the `homeserver.yaml` file. I suggest you search for the Values because the file is very long.
Uncomment / add and edit the following lines:

```
server_name: "matrix.domain.de"

enable_registration: false
password_config.enabled: false

oidc_providers:
# For use with Keycloak
  - idp_id: keycloak
    idp_name: YOURNAME
    issuer: "https://id.domain.de/auth/realms/YOURREALM"
    client_id: "matrix.domain.de"
    client_secret: "YOURSECRET"
    scopes: ["profile"]
```

**It is very important to remove the `openid` Scope which is preset. Things will not work if the
`openid` Scope is set.**

Now restart your Matrix Server. You should now be able to login with your Keycloak as an SSO Provider.
