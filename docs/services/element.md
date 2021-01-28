## Element WebClient 
```yaml 
version: "3.9"

services:
  element:   
    image: vectorim/element-web
    restart: always
    volumes:
      - '/srv/comms/element/data/config.json:/app/conig.json'
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_element.loadbalancer.server.port=80"
      - "traefik.http.routers.r_element.rule=Host(`element.domain.de`)"
      - "traefik.http.routers.r_element.entrypoints=websecure"
      - "traefik.http.routers.r_element.tls=true"
      - "traefik.http.routers.r_element.tls.certresolver=myresolver"
    networks:
      - proxy    
```

### Config.json 
First create a config.json for this you can use the following command:

```bash
touch /srv/comms/element/data/config.json 
```

Element supports a variety of settings to configure default servers, behaviour, themes, etc.
See the [configuration docs](https://github.com/vector-im/element-web/blob/develop/docs/config.md#desktop-app-configuration) for more details.

