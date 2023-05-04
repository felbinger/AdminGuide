# OpenLDAP

Ich habe viele vorgefertigte Docker Images getestet, und kam zu dem Entschluss, dass das Image
von `osixia/openldap:1.4.0` am besten funktioniert.
Leider wird aber weder der [bcrypt hashing Algorithmus](https://en.wikipedia.org/wiki/Bcrypt) noch
der [PBKDF2 hashing Algorithmus](https://en.wikipedia.org/wiki/PBKDF2) unterstützt.
Somit verwenden wir das Image von osixia als Basis und fügen den bcrypt hashing Algorithmus hinzu (
Siehe [howardlau1999/openldap-bcrypt-docker](https://github.com/howardlau1999/openldap-bcrypt-docker)).

Ein Freund von mir, welcher mich auch bei dem AdminGuide unterstützt, hat ein eigenes phpldapadmin image, welche nur
sichere hashing Algorithmen unterstützt und auf einem kleinen alpine image basiert.
[Siehe sein git repository](https://github.com/MarcelCoding/phpLDAPadmin) oder verwende einfach sein Docker Image
[`marcelcoding/phpldapadmin`](https://hub.docker.com/r/marcelcoding/phpldapadmin)

```yaml
version: '3.9'

services:
  ldap:
    image: howardlau1999/openldap-bcrypt
    restart: always
    env_file: .ldap.env
    environment:
      - "LDAP_ORGANISATION=Company Name"
      - "LDAP_DOMAIN=domain.de"
    ports:
      - "[::1]:389:389"
      - "[::1]:636:636"
    volumes:
      - "/srv/ldap/data:/var/lib/ldap"
      - "/srv/ldap/config:/etc/ldap/slapd.d"

  ldapadmin:
    image: marcelcoding/phpldapadmin
    restart: always
    environment:
      - "LDAP_HOST=ldap"
      - "LDAP_BIND_DN=cn=admin,dc=domain,dc=de"
    ports:
      - "[::1]:8000:80"
```

```shell
# .ldap.env
LDAP_ADMIN_PASSWORD=S3cr3T
```

## Eigene Schemas
### SSH Public Key Schema
Erstelle die `openssh-lpk.ldif` Datei (Ich hab es mehrmals versucht zu refactoren, aber ich lasse es einfach wie es ist)
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
Füge jetzt noch das Schema zu deinem LDAP Server hinzu.
```
$ ldapadd -Y EXTERNAL -H ldapi:/// -f openssh-lpk.ldif
SASL/EXTERNAL authentication started
SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
SASL SSF: 0
```

## LDAP Command Line Basics
Siehe den offiziellen [OpenLDAP Admin Guide](https://www.openldap.org/doc/admin24/)  
```sh
# query your ldap
ldapsearch -x -D 'cn=admin,dc=domain,dc=de' -w'admin' -b 'dc=domain,dc=de'

# add entries to your ldap
# 1. create ldif file which contains the entry
# 2. import it using ldapadd
ldapadd -x -D 'cn=admin,dc=domain,dc=de' -w'admin' -f your_entry.ldif
```
