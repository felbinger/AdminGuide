#### Admin Guide
- ...
- [x] ~~monitoring~~ <-- Verschoben
- [x] ~~backup~~ 
- [ ] Theorie
	- [x] vergleich nginx / traefik
	- [ ] use cases
		- [ ] ipv6 pro service
			- [ ] layer 3 kontrolle über die services
		- [ ] warum ipv4 -> v6 proxy
			- [ ] virtualisierung und wenig ipv4 adressen
			- [ ] ipv6 only server
		- [x] Vergleich der Möglichkeiten -> Grafik anpassen


#### Installation
- [ ] Basisinstallation
	- [x] Admin Gruppe
	- [x] Docker
	- [x] Backup
	- [ ] monitoring (will be fixed in further versions)
- [ ] nginx als Reverse Proxy
	- [ ] Aktuelle nginx ohne Proxy erklärung übernehmen und Anpassen (siehe unten)
	- [ ] usefull scripts 
		- [ ] searchport
		- [ ] ipv6 gen script
- [ ] traefik als Reverse Proxy
	- [ ] aktuelle Traefik ohne Proxy übernehmen??
- [ ] IPv4 -> IPv6 Proxy
	- [ ] nginx file

- [x] Alles mit Cloudflare raus
- [x] Basisinstallation  -> Grafik anpassen (xml in jpg drinne)

- [x] Backup:
	- [x] Ordner mit SSL Zertifikaten speichern (/root/acme.sh oder /etc/ssl)
- [ ] nginx ohne Proxy
	- [ ] Bilder
	- ![[Pasted image 20250805224551.png]]
	- ![[Pasted image 20250805224712.png]]
	- ![[Pasted image 20250805224846.png]]
	- [ ] Client IP Address Filtering -> Tipp: Ipv6 Subnet hinzufügen (wenn vorhanden)
	- [ ] IPv6
		- [ ] add del line beneath every ipv6
	- [ ] nginx service datei: erster Server Block löschen

#### docker-compose files
- [x] parse all docker-compose to docker compose


#### Nginx files:
- [ ] http2 im listener testen ob benötigt wenn http2 = on
- [ ] ipv6 redirect global file
- [ ] überall OCSP stapling raus
- [ ] hinzufügen ```
	- [ ] ssl_ecdh_curve X25519:prime256v1:secp384r1;
	- [ ] http2 on;

#### Backup
- [ ] write automation script
  - [ ] refresh all backups
  - [ ] create new archives for every not registered folder in /srv


#### interfaces
- [ ] change interface to $interface