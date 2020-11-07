# OpenLDAP

## Install:
Create you openldap service in the main `docker-compose.yml` file:
```yaml
  ldap:
    image: osixia/openldap:1.4.0
    environment:
      - 'LDAP_DOMAIN=demo.de'
      - 'LDAP_ADMIN_PASSWORD=admin'
```

Start the OpenLDAP server and open a shell to configure it:
```sh
docker-compose up -d ldap
docker-compose exec ldap /bin/bash
```


## Basics:
### Query your LDAP:
```
> ldapsearch -x -b 'dc=demo,dc=de' -D 'cn=admin,dc=demo,dc=de' -w'admin'
# extended LDIF
#
# LDAPv3
# base <dc=demo,dc=de> with scope subtree
# filter: (objectclass=*)
# requesting: ALL
#

# demo.de
dn: dc=demo,dc=de
objectClass: top
objectClass: dcObject
objectClass: organization
o: Example Inc.
dc: demo

# admin, demo.de
dn: cn=admin,dc=demo,dc=de
objectClass: simpleSecurityObject
objectClass: organizationalRole
cn: admin
description: LDAP administrator
userPassword:: e1NTSEF9WStETEowcnZpQW91YkhmT01qemVYWlI2UlBOSFQvZmQ=

# search result
search: 2
result: 0 Success

# numResponses: 3
# numEntries: 2

```

### Create two organization units: Groups and Users (aka People):
* Create a file with the extension `.ldif`:
    ```ldif
    dn: ou=groups,dc=demo,dc=de
    objectClass: organizationalUnit
    ou: groups

    dn: ou=people,dc=demo,dc=de
    objectClass: organizationalUnit
    ou: users
    ou: people
    ```
* Add the created `.ldif` file using the command:
    ```
    > ldapadd -x -D 'cn=admin,dc=demo,dc=de' -w'admin' -f FILENAME.ldif
    adding new entry "ou=groups,dc=demo,dc=de"
    adding new entry "ou=people,dc=demo,dc=de"
    ```
* Query again:
    ```
    > ldapsearch -x -b 'dc=demo,dc=de' -D 'cn=admin,dc=demo,dc=de' -w'admin'
    ...

    # demo.de
    dn: dc=demo,dc=de
    objectClass: top
    objectClass: dcObject
    objectClass: organization
    o: Example Inc.
    dc: demo

    # admin, demo.de
    dn: cn=admin,dc=demo,dc=de
    objectClass: simpleSecurityObject
    objectClass: organizationalRole
    cn: admin
    description: LDAP administrator
    userPassword:: e1NTSEF9WStETEowcnZpQW91YkhmT01qemVYWlI2UlBOSFQvZmQ=

    # groups, demo.de
    dn: ou=groups,dc=demo,dc=de
    objectClass: organizationalUnit
    ou: groups

    # people, demo.de
    dn: ou=people,dc=demo,dc=de
    objectClass: organizationalUnit
    ou: users
    ou: people

    # search result
    search: 2
    result: 0 Success

    # numResponses: 5
    # numEntries: 4

    ```

## Custom Schemas:

### BCrypt Password Hashing Algorithm
TODO: find new interface which supports bcrypt for password 

Resources:  
* [https://github.com/wclarie/openldap-bcrypt](https://github.com/wclarie/openldap-bcrypt)
* [https://github.com/howardlau1999/openldap-bcrypt-docker](https://github.com/howardlau1999/openldap-bcrypt-docker)

Build the docker image with openldap support:
```sh
git clone https://github.com/howardlau1999/openldap-bcrypt-docker /home/admin/images/main/openldap/
sudo docker build -t howardlau1999/openldap /home/admin/images/main/openldap/
```

If you want to reuse your existing data (without the bcrypt schema) you need to enable it:
```sh
$ cat << EOF > enable-bcrypt.ldif
# Add bcrypt support
dn: cn=module{0},cn=config
changetype: modify
add: olcModuleLoad
olcModuleLoad: pw-bcrypt
EOF

$ ldapadd -Y EXTERNAL -H ldapi:/// -f enable-bcrypt.ldif
```

Afterwards you can test it:
```bash
$ slappasswd -h '{BCRYPT}' -o module-load="/usr/lib/ldap/pw-bcrypt.so" -s randompassword
{BCRYPT}$2b$08$WQdWtD5L9LqIxcGG0xjiieM6./BAv/fbQOvSFnbF/REiLW6kg4eqq
```

You only need the binary... /usr/lib/ldap/pw-bcrypt.so.0.0 -> simply mount it to the old container...

### SSH Public Key
* Create the ldif file (do not try to refactor this...):
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
* Add the ldif file:
    ```
    $ ldapadd -Y EXTERNAL -H ldapi:/// -f openssh-lpk.ldif
    SASL/EXTERNAL authentication started
    SASL username: gidNumber=0+uidNumber=0,cn=peercred,cn=external,cn=auth
    SASL SSF: 0
    ```

## Example Entry
### Example Person
```
dn: uid=USERNAME,ou=people,dc=DOMAIN,dc=TLD
cn: FIRST_NAME LAST_NAME
gidnumber: 1000
givenname: FIRST_NAME
homedirectory: /home/USERNAME
loginshell: /bin/false
mail: EMAIL
objectclass: top
objectclass: shadowAccount
objectclass: inetOrgPerson
objectclass: organizationalPerson
objectclass: person
objectclass: ldapPublicKey
objectclass: posixAccount
sn: LAST_NAME
sshpublickey: ssh-rsa SSH_KEY DESCRIPTION
uid: USERNAME
uidnumber: 1000
userpassword: {SSHA}THIS_IS_A_INVALID_HASH_UPDATE_IT
```


## ApacheDirectoryStudio
* local port fwd: ssh an2ic3.de -L 1389:192.168.1.7:389
