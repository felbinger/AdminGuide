# Matrix Telegram Bridge

```yml
  mautrix-telegram:
    image: dock.mau.dev/mautrix/telegram
    restart: always
    volumes:
      - "/srv/comms/mautrix-telegram:/data:Z"
```

First we need to [generate the configuration](https://docs.mau.fi/bridges/python/setup/docker.html?bridge=telegram) for the Matrix Bridge:
```shell
docker-compose up -d mautrix-telegram
docker-compose stop mautrix-telegram
nano /srv/comms/mautrix-telegram/config.yaml
```

Next we're going to generate the registration file:
```shell
docker-compose up -d mautrix-telegram
```

Lastly we register the bridge in our synapse `homeserver.yaml` and restart the homeserver:
```shell
ln /srv/comms/mautrix-telegram/registration.yaml /srv/comms/synapse/mautrix-telegram.yaml

nano /srv/comms/synapse/homeserver.yaml
# locate the next line and add the second line
#app_service_config_files:
# - /data/mautrix-telegram.yaml

docker-compose rm -fs synapse
docker-compose up -d synapse
```

## Connect your Telegram Account
The Bridge uses the following Account: `@telegrambot:matrix.domain.de`  
[Simply send the command `login`, and follow the instructions to connect your Account](https://docs.mau.fi/bridges/python/telegram/authentication.html)  