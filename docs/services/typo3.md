# TYPO3

### Dockerfile
The current [dockerhub](https://hub.docker.com/r/martinhelmich/typo3/) repo contains various versions, all manually setup.  
For development purposes, a 10.4 [Dockerfile](https://github.com/Ziehnert/Typo3-docker) exists, containing an automatic setup using sqlite.

```yaml
  typo3:
    build: martinhelmich/typo3:$VERSION
    restart: always
    ports:
      - "[::1]:8000:80"
    volumes:
      - "/srv/typo3/conf:/var/www/html/typo3conf/"
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
          - "traefik.http.services.srv_typo3.loadbalancer.server.port=80"
          - "traefik.http.routers.r_typo3.rule=Host(`typo3.domain.de`)"
          - "traefik.http.routers.r_typo3.entrypoints=websecure"
    ```

After the installation, you won't be able to access the backend unless you specify the proxy in a new config file:
```php
# /srv/typo3/conf/AdditionalConfiguration.php

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
