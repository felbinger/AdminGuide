Checkout the [official guide](https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker)

I suggest you create a new stack for jitsi:
```bash
# create directories
mkdir -p /home/admin/{services,images}/jitsi/ /srv/jitsi

# create stack network
docker network inspect ${name} >/dev/null 2>&1 || \
docker network create --subnet 192.168.110.0/24 jitsi
```

Afterwars you can download the required files from the [jitsi/docker-jitsi-meet](https://github.com/jitsi/docker-jitsi-meet) github repository
```
wget https://raw.githubusercontent.com/jitsi/docker-jitsi-meet/master/docker-compose.yml -O /home/admin/services/jitsi/docker-compose.yml
wget https://raw.githubusercontent.com/jitsi/docker-jitsi-meet/master/env.example -O /home/admin/services/jitsi/.env

# generate new secrets
cd /home/admin/services/jitsi/
curl https://raw.githubusercontent.com/jitsi/docker-jitsi-meet/master/gen-passwords.sh | bash

# change configuration directory
sed -i 's|CONFIG=.*|CONFIG=/srv/jitsi|g' .env
```

Afterwards you may configure the .env file.

## Use Traefik
Modify web services:
* remove port forwardings
* add traefik labels
* connect network: proxy

After your changes the web service should look like this:
```yaml
    web:
        image: jitsi/web:latest
        restart: ${RESTART_POLICY}
        # removed ports forwarding
        # added traefik labels
        labels:
            - "traefik.enable=true"
            - "traefik.http.services.srv_jitsi.loadbalancer.server.port=80"
            - "traefik.http.routers.r_jitsi.rule=Host(`jitsi.domain.de`)"
            - "traefik.http.routers.r_jitsi.entrypoints=websecure"
            - "traefik.http.routers.r_jitsi.tls.certresolver=myresolver"
        volumes:
            - ${CONFIG}/web:/config:Z
            - ${CONFIG}/transcripts:/usr/share/jitsi-meet/transcripts:Z
        environment:
            - ENABLE_LETSENCRYPT
            - ...
            - TOKEN_AUTH_URL
        networks:
            # added proxy network
            proxy:
            meet.jitsi:
                aliases:
                    - ${XMPP_DOMAIN}
```

## Use LDAP Auth Backend
Modify prosody service:
* connect network: database
* configure ldap credentials

After your changes the prosody service should look like this:
```yaml
    # XMPP server
    prosody:
        image: jitsi/prosody:latest
        restart: ${RESTART_POLICY}
        expose:
            - '5222'
            - '5347'
            - '5280'
        volumes:
            - ${CONFIG}/prosody/config:/config:Z
            - ${CONFIG}/prosody/prosody-plugins-custom:/prosody-plugins-custom:Z
        environment:
            - AUTH_TYPE
            - ...
            - TZ
        networks:
            database:
            meet.jitsi:
                aliases:
                    - ${XMPP_SERVER}
```

The LDAP section of your `.env` should look like this (the not included keys are irrelevant if you don't use ldaps inside the docker network):
```bash
# LDAP url for connection
LDAP_URL=ldap://ldap

# LDAP base DN. Can be empty
LDAP_BASE=DC=domain,DC=com

# LDAP user DN. Do not specify this parameter for the anonymous bind
LDAP_BINDDN=CN=admin,DC=domain,DC=com

# LDAP user password. Do not specify this parameter for the anonymous bind
LDAP_BINDPW=S3cr3T

# LDAP filter. Tokens example:
# %1-9 - if the input key is user@mail.domain.com, then %1 is com, %2 is domain and %3 is mail
# %s - %s is replaced by the complete service string
# %r - %r is replaced by the complete realm string
#LDAP_FILTER=(sAMAccountName=%u)
# This filter only grants members of the jitsi group access
LDAP_FILTER=(&(objectclass=person)(&(memberof=cn=jitsi,ou=groups,dc=domain,dc=de))(uid=%u))

# ...
```

## Configuration
All configuration are stored in the `/srv/jitsi` directory:
* You can't modify `/srv/jitsi/web/config.js`, because it will be generated on container start, but you can update the attributes in the .env file
* You can update the settings of your interface by modifying `/srv/jitsi/web/interface_config.js`

## Extend your Jitsi instance
### Etherpad
Etherpad allows you to edit documents collaboratively in real-time.

You can find the [etherpad.yml](https://github.com/jitsi/docker-jitsi-meet/blob/master/etherpad.yml) in which the service is defined, in the github repo.
I suggest you copy the etherpad service to your `docker-compose.yml`.

### Jibri
The [Jitsi Broadcasting Infrastructure](https://github.com/jitsi/jibri) provides services for recording or streaming.

You can find the [jibri.yml](https://github.com/jitsi/docker-jitsi-meet/blob/master/jibri.yml) in which the service is defined, in the github repo.  
I suggest you copy the jibri service to your `docker-compose.yml`.

### Enable JVB Statictics (for monitoring)
You can enable the colibri api of the jvb service by simply comment out JVB_ENABLE_APIS in the .env file.
```bash
# A comma separated list of APIs to enable when the JVB is started [default: none]
# See https://github.com/jitsi/jitsi-videobridge/blob/master/doc/rest.md for more information
JVB_ENABLE_APIS=rest,colibri
```

You can now request the statistics from the api:
```bash
ip=$(docker inspect jitsi_jvb_1 | jq ".[0].NetworkSettings.Networks.jitsi.IPAddress" | tr -d '"')
curl -s "http://${ip}:8080/colibri/stats" | jq
```
