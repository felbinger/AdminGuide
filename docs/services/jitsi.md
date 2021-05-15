Checkout the [official guide](https://jitsi.github.io/handbook/docs/devops-guide/devops-guide-docker)

I suggest you create a new stack for jitsi:
```bash
# create directories
mkdir -p /home/admin/{services,images}/jitsi/ /srv/jitsi

# create stack network
docker network inspect ${name} >/dev/null 2>&1 || \
docker network create --subnet 192.168.110.0/24 jitsi
```

Afterwards you can download the required files from the [jitsi/docker-jitsi-meet](https://github.com/jitsi/docker-jitsi-meet) github repository
```
wget https://raw.githubusercontent.com/jitsi/docker-jitsi-meet/master/docker-compose.yml -O /home/admin/services/jitsi/docker-compose.yml
wget https://raw.githubusercontent.com/jitsi/docker-jitsi-meet/master/env.example -O /home/admin/services/jitsi/.env

# generate new secrets
cd /home/admin/services/jitsi/
curl https://raw.githubusercontent.com/jitsi/docker-jitsi-meet/master/gen-passwords.sh | bash

# change configuration directory
sed -i 's|CONFIG=.*|CONFIG=/srv/jitsi|g' .env
```

Next step is to configure the .env file.

## Use Traefik
Modify web services:
<ul>
  <li>
    remove port forwardings
  </li>
  <li>
    add traefik labels
  </li>
  <li>
    connect network: proxy
  </li>
</ul>

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
<ul>
  <li>
    connect network: database
  </li>
  <li>
    configure ldap credentials
  </li>
</ul>


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
All configurations are stored in the `/srv/jitsi` directory:
<ul>
  <li>
    You can't modify <code>/srv/jitsi/web/config.js</code>, because it will be regenerated on container start, but you can update the attributes in the .env file
  </li>
  <li>
    You can update the settings of your interface by modifying <code>/srv/jitsi/web/interface_config.js</code>
  </li>
</ul>


## Extend your Jitsi instance
### Etherpad
Etherpad allows you to edit documents collaboratively in real-time.

You can find the [etherpad.yml](https://github.com/jitsi/docker-jitsi-meet/blob/master/etherpad.yml) in which the service is defined, in the github repo.
I suggest you copy the etherpad service to your `docker-compose.yml`.
You can also add some environment variables to connect your own database. Your `.env` file should look like this:
```bash
DB_TYPE=postgres
DB_HOST=localhost
DB_PORT=5432
DB_NAME=etherpad
DB_USER=etherpad
DB_PASS=S3cR3T
#DB_CHARSET= This is only for MySQL
#DB_FILENAME= Just for SQLite or DirtyDB
```
Look also the [available database types](https://www.npmjs.com/package/ueberdb2). Now you have to put in these environment variables into your `docker-compose.yml`. This could look like this:
```yaml
    etherpad:
      environment:
        - ...
        - DB_TYPE=${DB_TYPE}
        - DB_HOST=${DB_HOST}
        - DB_PORT=${DB_PORT}
        - DB_NAME=${DB_NAME}
        - DB_USER=${DB_USER}
        - DB_PASS=${DB_PASS}
        - ...
```

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

## Export Metrics
You can export the metrics by using a prometheus exporter:
```yaml
    jitsi2prometheus:
        image: ghcr.io/an2ic3/jitsi2prometheus
        restart: always
        networks:
            meet.jitsi:
            monitoring
```

Don't forget to add your jitsi2prometheus instance to the prometheus configuration:
```yaml
...
scrape_configs:
   ...
  - job_name: 'jitsi'
    static_configs:
      - targets: ['jitsi2prometheus:8080']
```
