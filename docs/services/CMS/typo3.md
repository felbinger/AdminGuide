# TYPO3

### Dockerfile

The current [dockerhub](https://hub.docker.com/r/martinhelmich/typo3/) repo contains various versions, all manually setup.

For development purposes, a 10.4 [Dockerfile](https://github.com/Ziehnert/Typo3-docker) containing an automatic setup using sqlite.

### docker-compose.yaml

```yaml
  typo3:
    build: martinhelmich/typo3:$VERSION
    restart: always
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_t3.loadbalancer.server.port=80"
      - "traefik.http.routers.r_t3.rule=Host(`typo3.domain.de`)"
      - "traefik.http.routers.r_t3.entrypoints=websecure"
      - "traefik.http.routers.r_t3.tls=true"
      - "traefik.http.routers.r_t3.tls.certresolver=myresolver"
    networks:
      - proxy
      - database
```

### Typo3 through a reverse proxy

After the installtion, you won't be able to access the backend unless you specify the proxy in a new config file.

```yaml
  typo3:
    build: martinhelmich/typo3:$VERSION
    restart: always
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_t3.loadbalancer.server.port=80"
      - "traefik.http.routers.r_t3.rule=Host(`typo3.domain.de`)"
      - "traefik.http.routers.r_t3.entrypoints=websecure"
      - "traefik.http.routers.r_t3.tls=true"
      - "traefik.http.routers.r_t3.tls.certresolver=myresolver"
    volumes:
      - "/srv/main/typo3/conf:/var/www/html/typo3conf/"
    networks:
      - proxy
      - database
```

```php
# /srv/main/typo3/conf/AdditionalConfiguration.php

<?php
// '*' tells TYPO3 to use the value of reverseProxyIP for comparison
$GLOBALS['TYPO3_CONF_VARS']['SYS']['reverseProxySSL'] = '*';
// reverseProxyIP equals the IP address of your reverse proxy (e.g. traefik)
$GLOBALS['TYPO3_CONF_VARS']['SYS']['reverseProxyIP'] = '<your reverse proxy IP>';
// trustedHostsPattern contains your domain OR a pattern for your requirements
$GLOBALS['TYPO3_CONF_VARS']['SYS']['trustedHostsPattern'] = 'typo3.domain.de';
// use ip address from HTTP_X_FORWARDED_FOR for remote address and
// use host name from HTTP_X_FORWARDED_HOST
$GLOBALS['TYPO3_CONF_VARS']['SYS']['reverseProxyHeaderMultiValue'] = 'first';
?>
```
