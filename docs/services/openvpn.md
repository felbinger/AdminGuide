# OpenVPN

```yaml
services:
  openvpn:
    image: kylemanna/openvpn
    restart: always
    ports:
     - "1194:1194/udp"
    cap_add:
     - NET_ADMIN   
    volumes:
     - /srv/main/openvpn/conf:/etc/openvpn
```

First you need to initialize the configuration files and certificates. 

```shell
docker-compose run --rm openvpn ovpn_genconfig -u udp://vpn.domain.de
docker-compose run --rm openvpn ovpn_initpki
```

Afterwards you can start the server 

```shell
docker-compose up -d openvpn
```

You can generate the certificates as follows 

```shell
export CLIENTNAME="your_client_name"
# with a passphrase (recommended)
docker-compose run --rm openvpn easyrsa build-client-full $CLIENTNAME
# without a passphrase (not recommended)
docker-compose run --rm openvpn easyrsa build-client-full $CLIENTNAME nopass
```

Retrieve the client configuration with embedded certificates

```shell
docker-compose run --rm openvpn ovpn_getclient $CLIENTNAME > $CLIENTNAME.ovpn
```

Revoke a client certificate

```shell
# Keep the corresponding crt, key and req files.
docker-compose run --rm openvpn ovpn_revokeclient $CLIENTNAME
# Remove the corresponding crt, key and req files.
docker-compose run --rm openvpn ovpn_revokeclient $CLIENTNAME remove
```