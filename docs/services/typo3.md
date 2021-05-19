### Dockerfile

The current LTS image on [dockerhub](https://hub.docker.com/r/martinhelmich/typo3/) is currently one minor release behind.

You can still use it for older versions, or the experimental version 11, but for latest LTS release you have to use this file

```Dockerfile
FROM php:7.4-apache-buster
LABEL maintainer="Martin Helmich <typo3@martin-helmich.de>"

# Install TYPO3
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        wget \
# Configure PHP
        libxml2-dev libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libpq-dev \
        libzip-dev \
        zlib1g-dev \
# Install required 3rd party tools
        graphicsmagick && \
# Configure extensions
    docker-php-ext-configure gd --with-libdir=/usr/include/ --with-jpeg --with-freetype && \
    docker-php-ext-install -j$(nproc) mysqli soap gd zip opcache intl pgsql pdo_pgsql && \
    echo 'always_populate_raw_post_data = -1\nmax_execution_time = 240\nmax_input_vars = 1500\nupload_max_filesize = 32M\npost_max_size = 32M' > /usr/local/etc/php/conf.d/typo3.ini && \
# Configure Apache as needed
    a2enmod rewrite && \
    apt-get clean && \
    apt-get -y purge \
        libxml2-dev libfreetype6-dev \
        libjpeg62-turbo-dev \
        libmcrypt-dev \
        libpng-dev \
        libzip-dev \
        zlib1g-dev && \
    rm -rf /var/lib/apt/lists/* /usr/src/*

RUN cd /var/www/html && \
    wget -O download.tar.gz https://get.typo3.org/10.4.16 && \
    tar -xzf download.tar.gz && \
    rm download.* && \
    ln -s typo3_src-* typo3_src && \
    ln -s typo3_src/index.php && \
    ln -s typo3_src/typo3 && \
    cp typo3/sysext/install/Resources/Private/FolderStructureTemplateFiles/root-htaccess .htaccess && \
    mkdir typo3temp && \
    mkdir typo3conf && \
    mkdir fileadmin && \
    mkdir uploads && \
    touch FIRST_INSTALL && \
    chown -R www-data. .

# Configure volumes
VOLUME /var/www/html/fileadmin
VOLUME /var/www/html/typo3conf
VOLUME /var/www/html/typo3temp
VOLUME /var/www/html/uploads
```

### docker-compose.yaml

```yaml
  typo3:
    build: /home/admin/images/main/typo3/
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
    build: /home/admin/images/main/typo3/
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
