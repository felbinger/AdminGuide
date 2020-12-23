I tested a lot of prebuild docker images and I came to the conclusion that the one from `osixia/openldap:1.4.0` works best.
Unfortunately neither the [bcrypt hashing algorithm](https://en.wikipedia.org/wiki/Bcrypt) nor the [PBKDF2 hashing algorithm](https://en.wikipedia.org/wiki/PBKDF2) is being support.
So, we are going to use osixia's image as base, and add the bcrypt hashing algorithm (checkout [howardlau1999/openldap-bcrypt-docker](https://github.com/howardlau1999/openldap-bcrypt-docker)).

I like to combind every service with a administrative webinterface. ~~I use phpldapadmin which is also available from osixia: [`osixia/docker-phpLDAPadmin`](https://github.com/osixia/docker-phpLDAPadmin).
Today's version of phpldapadmin from osixia is 1.2.5, but there is version 1.2.6.2 (which supports bcrypt), so let's clone also this git repository to build the image with the correct version of phpldapadmin.~~
A friend of mine, who's also supporting me with the admin guide, build a custom phpldapadmin image, which only supports secure hashing algorithms and uses a small alpine base image. 
[Checkout his git repository](https://github.com/MarcelCoding/phpLDAPadmin) or simply use his docker image: [`marcelcoding/phpldapadmin`](https://hub.docker.com/r/marcelcoding/phpldapadmin)

So let's clone the repositories and build our own ldap image:  
```sh
git clone https://github.com/howardlau1999/openldap-bcrypt-docker.git \
  /home/admin/images/main/openldap
sudo docker build -t local/openldap \
  /home/admin/images/main/openldap
```

Afterwards we can define the services in the main `docker-compose.yml`
```yaml
  ldap:
    image: local/openldap
    restart: always
    environment:
      - "LDAP_ORGANISATIOn=Company Name"
      - "LDAP_DOMAIN=domain.de"
      - "LDAP_ADMIN_PASSWORD=S3cr3T"
    volumes:
      - "/srv/main/ldap/data:/var/lib/ldap"
      - "/srv/main/ldap/config:/etc/ldap/slapd.d"
    networks:
      - database

  ldapadmin:
    image: marcelcoding/phpldapadmin
    restart: always
    environment:
      - 'LDAP_HOST=ldap'
      - 'LDAP_BIND_DN=cn=admin,dc=domain,dc=de'
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_ldapadmin.loadbalancer.server.port=80"
      - "traefik.http.routers.r_ldapadmin.rule=Host(`ldapadmin.domain.de`)"
      - "traefik.http.routers.r_ldapadmin.entrypoints=websecure"
      - "traefik.http.routers.r_ldapadmin.tls.certresolver=myresolver"
    networks:
      - database
      - proxy

```

## Custom Schemas
### SSH Public Key Schema
Create the `openssh-lpk.ldif` file (I tried to refactor this multiple times, just leave it as it is...)
```ldif
# AUTO-GENERATED FILE - DO NOT EDIT!! Use ldapmodify.
# CRC32 f6bf57a2
dn: cn=openssh-lpk,cn=schema,cn=config
objectClass: olcSchemaConfig
cn: openssh-lpk
olcAttributeTypes: {0}( 1.3.6.1.4.1.24552.500.1.1.1.13 NAME 'sshPublicKey' DES
C 'MANDATORY: OpenSSH Public key' EQUALITY octetStringMatch SYNTAX 1.3.6.1.4.
1.1466.115.121.1.40 )
olcObjectClasses: {0}( 1.3.6.1.4.1.24552.500.1.1.2.0 NAME 'ldapPublicKey' DESC
'MANDATORY: OpenSSH LPK objectclass' SUP top AUXILIARY MAY ( sshPublicKey $
uid ) )
```
Add the schema to your ldap server:
```
$ ldapadd -Y EXTERNAL -H ldapi:/// -f openssh-lpk.ldif
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
```

## LDAP Command Line Basics
Checkout the official [OpenLDAP Admin Guide](https://www.openldap.org/doc/admin24/)  
```sh
# query your ldap
ldapsearch -x -D 'cn=admin,dc=domain,dc=de' -w'admin' -b 'dc=domain,dc=de'

# add entries to your ldap
# 1. create ldif file which contains the entry
# 2. import it using ldapadd
ldapadd -x -D 'cn=admin,dc=domain,dc=de' -w'admin' -f your_entry.ldif
```
