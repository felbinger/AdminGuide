### Matrix Discord Bridge
(Only tested on ARM)

Docker-compose
```yaml
version: '3.9'

services:
    mx-puppet-discord:
        image: flyffies/mx-puppet-discord # ARM Image
        image: sorunome/mx-puppet-discord
        restart: always
        volumes:
            - '/srv/main/matrix-discord-bridge/:/bridge/'
        environment:
            CONFIG_PATH: '/bridge/config.yaml'
            REGISTRATION_PATH: '/bridge/registration.yaml'
        networks:
            - matrix

networks:
    matrix:
        external: true
```
NOTE: You have to create a matrix Network `sudo docker network create matrix`

Start the Container to generate the `config.yaml`.

Change a few things in the config
```yaml
bridge:
    bindAddress: 0.0.0.0
provisioning:
    whitelist:
        - "@.*:matrix\\.domain\\.de"
```
Now add the `registration.yaml` to the `homeserver.yaml`
```yaml
app_service_config_files:
    - "/data/discord/registration.yaml"
```
You have to add the `registration.yaml` as volume to the Matrix Homeserver

