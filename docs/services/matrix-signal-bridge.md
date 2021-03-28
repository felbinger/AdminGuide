## Matrix Signal Bridge
(Only tested on ARM)
Docker-compose
```yaml
version: "3.9"

services:
  mautrix-signal:
    container_name: mautrix-signal
    image: heywoodlh/mautrix-signal
    restart: always
    volumes:
    - /srv/main/bridge:/data
    - /srv/main/signald:/signald
    depends_on:
      - signald
    ports:
      - 29328:29328
    networks:
        - matrix

  signald:
    container_name: signald
    #image: docker.io/finn/signald
    image: mik/signald # my self builed image for arm
    restart: unless-stopped
    volumes: 
      - /srv/main/signald:/signald
    networks:
        - matrix
  
  signal-bridge-db:
    image: postgres
    restart: always
    environment:
      POSTGRES_USER: mautrixsignal
      POSTGRES_DATABASE: mautrixsignal
      POSTGRES_PASSWORD: mautrixsignal
    volumes:
    - /srv/main/signal-bridge-db:/var/lib/postgresql/data
    networks:
        - matrix

networks:
    matrix:
        external: true

```
If you use ARM you must build `signald` from source else you could use the image from `docker.io/finn/signald`.
Note: You should create a Matrix Network in Docker (`sudo docker network create matrix`)
Start the Container to generate the config.
In the `bridge` Folder is now a `config.yaml`.
You have to change some things:
```yaml
homeserver:
    address: https://example.com
    domain: example.com

appservice:
    address: https://mautrix-signal:29328 # the hostname/ip of the bridge container
    database: postgres://mautrixsignal:mautrixsignal@signal-bridge-db/mautrixsignal
bridge:
    permissions:
        example.com user # adds all users of the homeserver 'example.com'
        '@admin:example.com' admin # sets the user '@admin:example.com' as admin
        # you can add more users/admins
```
Restarting the container should generate a `registration.yaml`
Add this File (Full Path) as volume to your Matrix (Synapse) Container.
Add this to your `homeserver.yaml`
```yaml
app_service_config_files:
    - "/data/signal/registration.yaml" # path to the mounted file
```
Now restart all Containers (including Matrix).
Now invite `@signalbot:example.com` to a Direct Message Room.
Type `!signal help` to get all Commands.
Or type `!signal link` an Link your Signal Account.
