# Matrix Signal Bridge

```yml
  mautrix-signal:
    image: dock.mau.dev/mautrix/signal
    restart: always
    depends_on:
      - "signald"
    volumes:
      - "/srv/comms/mautrix-signal:/data:Z"
      - "/srv/comms/signald:/signald/:z"

  signald:
    image: docker.io/signald/signald
    restart: always
    volumes: 
      - "/srv/comms/signald:/signald:z"
```

First we need to [generate the configuration](https://docs.mau.fi/bridges/python/signal/setup-docker.html) for the Matrix Bridge:
```shell
docker-compose up -d signald mautrix-signal
docker-compose stop mautrix-signal
nano /srv/comms/mautrix-signal/config.yaml
```

Next we're going to generate the registration file:
```shell
docker-compose up -d mautrix-signal
```

Lastly we register the bridge in our synapse `homeserver.yaml` and restart the homeserver:
```shell
ln /srv/comms/mautrix-signal/registration.yaml /srv/comms/synapse/mautrix-signal.yaml

nano /srv/comms/synapse/homeserver.yaml
# locate the next line and add the second line
#app_service_config_files:
# - /data/mautrix-signal.yaml

docker-compose rm -fs synapse
docker-compose up -d synapse
```

## Connect your Signal Account
The Bridge uses the following Account: `@signalbot:matrix.domain.de`  
You can eighter use the `register <phone number>` command to only use signal via matrix, or simply link the matrix bridge (just like the regular desktop client) using `link` (scan the generate qr code with your phone afterwards). If you register your phone number and an error occurs try using the `--captcha` option as described [here](https://signald.org/articles/captcha/):
```
register --captcha <generated captcha> +49012345689
```