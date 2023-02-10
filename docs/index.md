# Startseite

Diese Informationssammlung beschreibt das von mir bevorzugte Verfahren zum 
Aufsetzen eines Linux Servers mit Anwendungen in Docker Containern. Hauptsächlich 
handelt es sich in meinem Fall um webbasierte Anwendungen. Diese werden nur über 
IPv6 mit einem Reverse Proxy ([Traefik](https://traefik.io/) als Docker Container, 
oder [`nginx`](https://www.nginx.com/) auf dem Host) erreichbar gemacht. Um die 
IPv4 Erreichbarkeit zu gewährleisten wird entweder Cloudflare Proxy (mit TLS 
Terminierung) oder ein eigener (transparenter) Proxy verwendet.

![Schaubild](img/schaubild_cloudflare-vs-transparent-proxy.png){: loading=lazy }

## Vor- und Nachteile von Cloudflare Proxy

Die Vorteile von Cloudflare Proxy sind neben des DDoS Schutzes, die Möglichkeit [Web 
Application Firewall](https://developers.cloudflare.com/waf/managed-rules/) / [Page 
Rules](https://www.cloudflare.com/features-page-rules/) auf die eingehenden Anfragen
anzuwenden. Als Nachteil ist hier anzuführen, dass der Datenverkehr der Nutzer bei 
Cloudflare entschlüsselt wird.

### Nutzern das direkte Verbinden zum Server verbieten

Wird Cloudflare verwendet, möchte man meist sicherstellen, dass sich niemand direkt 
mit dem Server verbinden kann, wodurch die Firewall Regeln umgangen werden könnten. 
Dazu kann der Reverse Proxy so konfiguriert werden, dass jede Anfrage ein TLS Client 
(mTLS) Zertifikat von der "Cloudflare Origin Pull CA" übermitteln muss. Die [Einrichtung 
bei Cloudflare ist in deren Dokumentation](https://developers.cloudflare.com/ssl/origin-
configuration/authenticated-origin-pull/set-up) beschreiben.

## Lokales HTTP Routing

Nachdem die Anfragen den Reverse Proxy auf unserem eigenen Host erreicht haben, werden 
diese je nach verwendetem Reverse Proxy über lokal gebundene Ports oder Docker Labels
an den Container weitergeleitet, der den Dienst bereitstellt.

## Verzeichnisstruktur

Jeder bereitgestellte Dienst erhält zwei Verzeichnisse:  
1. Im Verzeichnis `/home/admin/<service>` liegt die Containerdefinition (`docker-compose.yml`),  
2. die Daten des Dienstes werden im Verzeichnis `/srv/<service>` gespeichert.

### Umgebungsvariablen

Schützenswerte Umgebungsvariablen (Passwörter, API Tokens, ...) werden nicht in der 
Containerdefinition abgelegt, sondern in einer separaten `env`-Datei, um die Gefahr einer 
Offenlegung dieser (z. B. beim Teilen des Bildschirms) zu reduzieren. Diese tragen den 
Container-Namen des Dienstes im docker-compose Kontext.

Im folgenden Beispiel-Dienst (`service: example`, `service_name: example_srv`) würde die 
`env`-Datei unter dem Pfad `/home/admin/example/.example_srv.env` angelegt werden.
```yaml
# /home/admin/example/docker-compose.yml
services:
  example_srv:
    image: ...
    env_file: .example_srv.env
```

### Reverse Proxy

TODO: Hier text einfügen welche Vor-/Nachteile nginx/Traefik bieten:

* nginx: höherer Konfigurationsaufwand durch statische vhost config.
* Traefik: braucht für dynamische Konfiguration über gesettzte Docker Labels Zugriff auf Docker Daemon.
* Traefik: Dashboard

=== "Traefik"
    Da Traefik als Docker Container bereitgestellt wird, gilt die oben genannte Verzeichnisstruktur:

    * Containerdefinition: `/home/admin/traefik/docker-compose.yml`  
    * Env-Vars (hier DNS API Token): `/home/admin/traefik/.traefik.env`  
    * Daten (z.B. TLS Zertifikate): `/srv/traefik`  
=== "nginx"
    Da `nginx` nicht als Docker Container bereitgestellt wird, sondern direkt auf dem Host 
    installiert wird, gilt hier eine andere Verzeichnisstruktur.

    Die "Virtual-Host" Konfigurationsdateien liegen im Verzeichnis `/etc/nginx/sites-available/`
    unter der Domain, die Sie erreichbar machen.

    Die dazu notwendigen TLS Zertifikate liegen je nach verwendetem Proxy, der die IPv4 
    Erreichbarkeit sicherstellt, in unterschiedlichen Verzeichnissen.

### TLS Zertifikate
Wird der Reverse Proxy nur hinter Cloudflare erreichbar gemacht, können [Origin Server Zertifikat](
https://developers.cloudflare.com/ssl/origin-configuration/origin-ca/) verwendet werden. Diese
werden zwar vom Browser als ungültig angesehen, dies ist aufgrund des vorgeschalteten Cloudflare Proxies
jedoch irrelevant. Da diese Zertifikate von Cloudflare selbst ausgestellt werden, können die TLS Einstellungen 
der Domain dennoch auf "Full (Strict)" gesetzt werden.

Sofern der eigene transparente Proxy verwendet wird, muss das Zertifikat im Browser als valide angesehen werden,
da dieses direkt an den Nutzer weitergesendet wird. Kostenlose TLS Zertifikate können über Anbieter wie ZeroSSL 
oder Let's Encrypt bezogen werden.

=== "Traefik"
    Traefik verwendet als ACME Client [Lego](https://go-acme.github.io/lego/). Die Konfiguration dieses 
    kann der [Traefik Dokumentation](https://doc.traefik.io/traefik/https/acme/) entnommen werden.
    Die angeforderten Zertifikate und Privaten Schlüssel werden im `/srv/traefik` Volume des Traefik 
    Containers gespeichert.
=== "nginx"
    Wird `nginx` als Reverse Proxy eingesetzt beziehe ich die Zertifikate mithilfe des Shellskriptes
    [`acme.sh`](https://github.com/acmesh-official/acme.sh), welches ich unter dem root-Nutzer laufen lasse.
    Die resultierenden Privaten Schlüssel und Zertifkate werden im Verzeichnis `/root/.acme.sh/` gespeichert 
    und direkt von dort in der nginx V-Host Konfiguration eingebunden.

Prinzipiell ist die genutzte [ACME Challenge](https://letsencrypt.org/docs/challenge-types/) irrelevant, da ich
auch interne Dienste betreibe, die nicht aus dem Internet erreichbar sind, verwende ich prinzipiell die ACME-DNS-01 
Challenge. Sowohl [Traefik / Lego](https://doc.traefik.io/traefik/https/acme/#providers) als auch 
[`acme.sh`](https://github.com/acmesh-official/acme.sh/wiki/dnsapi) unterstützten eine Vielzahl an DNS API's
