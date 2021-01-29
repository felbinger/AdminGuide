## Element WebClient 
The Element web client can be used by [Matrix](./matrix.md).

```yaml 
  element:   
    image: vectorim/element-web
    restart: always
    volumes:
      - "/srv/comms/element/data/config.json:/app/conig.json"
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

### Configuration
First you need to create a `config.json`:
```shell
mkdir -p /srv/comms/element/data/
touch /srv/comms/element/data/config.json 
```
Element supports a variety of settings to configure default servers, behaviour, themes, etc.  
Checkout the [configuration docs](https://github.com/vector-im/element-web/blob/develop/docs/config.md#desktop-app-configuration) for more details.

