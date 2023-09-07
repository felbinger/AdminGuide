# OpenVPN

Einfacher und selbst gehosteter OpenSource VPN Dienst.

!!! info ""
	Auf Basis dessen, was man mit dem OpenVPN Server vorhat, empfehlen wir diesen nicht in einem Docker Container zu
	betreiben.
	Alternativen zu dem Docker Container wären es entweder direkt auf dem Host zu installieren oder eine vorhandene
	Infrastruktur zu verwenden (z. B. einen Router wie pfSense oder VyOS)

```yaml
version: '3.9'

services:
  openvpn:
    image: kylemanna/openvpn
    restart: always
    ports:
     - "1194:1194/udp"
    cap_add:
     - "NET_ADMIN"   
    volumes:
     - "/srv/openvpn:/etc/openvpn"
```

Zuerst muss man die Konfigurationsdateien und Zertifikate initialisieren:
```shell
docker compose run --rm openvpn ovpn_genconfig -u udp://vpn.domain.de
docker compose run --rm openvpn ovpn_initpki
```

Danach kann der Server gestartet werden
```shell
docker compose up -d openvpn
```

Die Zertifikate werden wie folgt generiert:
```shell
export CLIENTNAME="your_client_name"
# with a passphrase (recommended)
docker compose run --rm openvpn easyrsa build-client-full $CLIENTNAME
# without a passphrase (not recommended)
docker compose run --rm openvpn easyrsa build-client-full $CLIENTNAME nopass
```

Die Konfigurationsdatei für den Client kann wie folgt gespeichert werden:
```shell
docker compose run --rm openvpn ovpn_getclient $CLIENTNAME > $CLIENTNAME.ovpn
```

Um ein Client Zertifikat zu widerrufen:
```shell
# Keep the corresponding crt, key and req files.
docker compose run --rm openvpn ovpn_revokeclient $CLIENTNAME
# Remove the corresponding crt, key and req files.
docker compose run --rm openvpn ovpn_revokeclient $CLIENTNAME remove
```