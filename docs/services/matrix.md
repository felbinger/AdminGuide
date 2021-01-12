First add this configuration to you `docker-compose.yml`
```yaml
  matrix:
    container_name: matrix
    image: matrixdotorg/synapse
    restart: always
    volumes:
      - /srv/comms/matrix/data:/data
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
Befor starting this container you need to generate a configuration file. This command generates a `homeserver.yaml` configuartion file under /srv/comms/matrix
```yaml
docker run -it --rm -v "/srv/comms/matrix/data:/data" -e "SYNAPSE_SERVER_NAME=matrix.domain.de" -e "SYNAPSE_REPORT_STATS=no" matrixdotorg/synapse:latest generate
```
You have to specify the domain of the service using the SYNAPSE_SERVER_NAME environment variable. You also can enable anonymous statistics reporting by setting sthe SYNAPSE_REPORT_STATS to yes

After the command is done you can find the homeserver.yaml configurationfile in the data folder. 
Now you can start the service using docker-compose up -d matrix

### Register a new user 
You can enable the registration in your `homeserver.yaml` file:
```yaml
...
enable_registration: true
...
```

Don't forget to start the container after editing the option with `docker-compose up -d`

Now you can create a user using the command line:
```yaml
docker exec matrix register_new_matrix_user -u USERNAME -p PASSWORD -a -c /data/homeserver.yaml matrix.domain.de
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

By default, a SQL-Lite database is used, so we still need to comment it out.


``` yaml
#database:
# name: sqlite3
# args:
# database: /data/homeserver.db

```

Now you are finish and you can start the container with `docker-compose up -d`

### Reset password of user 

If you want to reset the assword run 
```yaml 
  docker exec -it -u www-data matrix hash_password -p PASSWORD
```

After the command is done you will become a password hash as std-out. 

After you have generated the password hash you can update the value in the database. First you shoud start a shell in the postgress container with 
``` yaml
docker exec -it matrix_postgresql /bin/bash
```
Next, you can connect to the database with the command 
```yaml
psql -u postgres -d synapse -w S3cr3T
```
Finally you can update the password with the help of 

```yaml
UPDATE users SET password_hash='$2a$12$xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx'
    WHERE name='@test:test.com';
```
Important do not forget the semicolon at the end of the line otherwise the UPDATE command will not work. Also PSQL is case sensitive so you have to pay attention to the upper and lower case.