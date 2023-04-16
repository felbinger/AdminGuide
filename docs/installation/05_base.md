# Basisinstallation

Jeder, der diese Informationssammlung nutzt, sollte in der Lage sein, seinen
Linux Server grundlegend einzurichten und abzusichern. Daher verzichte ich hier
auf Standardanleitungen und stelle lediglich die spezifischen Konzepte vor.

## Admin Gruppe

Ich gehe grundsätzlich davon aus, dass ich auf keinem System der alleinige
Administrator bin, weshalb auf allen Systemen eine Admin-Gruppe existiert,
die Rechte auf das Verzeichnis `/home/admin` hat.

```shell
groupadd -g 997 admin
mkdir -m 775 /home/admin
chown root:admin /home/admin
```

Die personalisierten Accounts der Systemadministratoren erhalten neben der `sudo`
Gruppenmitgliedschaft auch die Gruppe `admin`:

```shell
adduser nicof2000
usermod -aG sudo,admin nicof2000
```

## Docker

Die Installation von Docker - wie in der Docker Dokumentation bereits sehr gut beschrieben, -
verwenden wie zusätzlich einen Alias der uns den Tippaufwand für `sudo docker compose` erspart:

```shell
curl -fsSL https://get.docker.com | sudo bash
echo 'alias dc="sudo docker compose "' >> ~/.bashrc
```

## Proxy und Reverse Proxy

In den folgenden Kapiteln werden die sechs möglichen Kombinationen vorgestellt.

Welche der Konfigurationen man verwendet, ist jedem selbst überlassen.

### Meine Geschichte

Vielleicht hilft euch meine Geschichte, welche beschreibt, warum ich diese verschiedenen Verfahren einsetze. Früher
hatte ich einen kleinen Cloudserver, welcher sowohl über eine IPv4 Adresse als auch ein /64er IPv6 Netz verfügte. Auf
diesem Server lief letzten Endes eine Vorgängerversion des hier beschriebenen Konzepts.

Im weiteren Verlauf, administrierte ich einen dedizierten Server, der ebenfalls über eine IPv4 Adresse und ein /64er
IPv6 Netz verfügte. Da auf diesem jedoch mehrere virtuelle Maschinen betrieben werden sollten, musste ich mir eine
Möglichkeit überlegen, wie ich das HTTP Routing für Clients, die über IPv4 kamen gestaltete.

Zunächst verwendete ich dafür einen zentralisierten Reverse Proxy, welcher alle HTTP Requests annahm und dann zu den
jeweils verantwortlichen virtuellen Maschinen weiterleitete. Dort wurde ein weiterer Reverse Proxy betrieben, welcher
sich um das HTTP Routing zu den einzelnen Docker Containern kümmerte.

Dies hatte den großen Nachteil, dass zwangsläufig ein weiterer Reverse Proxy im Einsatz war, um die richtige virtuelle
Maschine zu adressieren. Für das Aufsetzen eines neuen Dienstes war plötzlich ein weiterer Schritt auf einer anderen
Maschine notwendig.

Zu einem späteren Zeitpunkt erhielten weitere Administratoren für eigene virtuelle Maschinen Zugriff auf diesen
dedizierten Server. Da ich diesen den Zugriff auf den Reverse Proxy, welcher das Routing zu den virtuellen Maschinen
verwehren wollte, verwendete ich zunächst Cloudflare Proxy, um die IPv4 Erreichbarkeit zu sichern und
zusätzlich weitere Schutzmaßnahmen (z. B. Denial of Service Schutz) für diesen dedizierten Server in Anspruch zu nehmen.

Spätestens seit Zensus
2022, [bei dem das Statistische Bundesamt durch die Verwendung des Cloudflare Proxies in Verruf geriet](https://www.kuketz-blog.de/zensus-2022-statistisches-bundesamt-hostet-bei-cloudflare/),
ist klar, dass auch die Verwendung des Cloudflare Proxys aus Privatsphäre-Gründen bedenklich ist (die übermittelten
Daten stehen Cloudflare unverschlüsselt zur Verfügung, da der Cloudflare Proxy die TLS Verbindung terminiert).

Vor allem durch unsicherheiten hinsichtlich
der [Abmahnwelle wegen Google Fonts](https://www.heise.de/news/DSGVO-Abmahnwelle-wegen-Google-Fonts-7206364.html) im
selben Jahr, konfigurierte ich mir einen eigenen (transparenten) Proxy, um zumindest für die IPv4 Erreichbarkeit eine
Alternative zu Cloudflare in der Hinterhand haben zu können.

Die Idee hinter diesem Proxy ist extrem einfach: Im DNS stehen für IPv6 (DNS AAAA-Record) die Adressen des eigentlichen
Webservers, sodass die Nutzer sich direkt mit diesem Verbinden können. Falls die Nutzer über keine IPv6 Konfiguration
verfügen, nutzen Sie den im IPv4 (DNS A-Record) hinterlegten IPv4-to-IPv6 Proxy, der die Anfragen dann über IPv6
weiterleitet, OHNE die TLS Verbindung zu terminieren. Dies hat den Vorteil das keine Zertifikate benötigt werden.

### IPv4-to-IPv6 Proxy

Dieser einfache IPv4-to-IPv6 Proxy unterstützt in seiner ersten Version lediglich HTTP Verbindungen auf Port 80 und TLS
Verbindungen auf Port 443. Eine Anpassung dieser Konfiguration um einige anderen Protokolle (SMTPs, IMAPs, POP3s) welche
TLS verwenden zu unterstützten ist denkbar.

Aus Gründen der Vollständigkeit hier einmal die nginx Konfiguration für den Proxy für Alpine Linux. Die Einrichtung ist
denkbar einfach: nginx installieren, die untenstehende Konfiguration kopieren und den Proxy starten:

```nginx
user nginx;
worker_processes auto;

error_log /var/log/nginx/error.log notice;
pid /var/run/nginx.pid;


events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                    '$status $body_bytes_sent "$http_referer" '
                    '"$http_user_agent" "$http_x_forwarded_for"';
    access_log /var/log/nginx/access.log  main;

    sendfile on;
    keepalive_timeout 65;

    server {
        listen 80 default_server;
        location / {
            return 301 https://$host$request_uri;
        }
    }
}

stream {
    # https://gist.github.com/kekru/c09dbab5e78bf76402966b13fa72b9d2#non-terminating-tls-pass-through
    server {
        listen 443;

        proxy_connect_timeout 1s;
        proxy_timeout 3s;

        resolver 1.1.1.1 1.0.0.1 [2606:4700:4700::1111] [2606:4700:4700::1001] ipv6=on ipv4=off;

        proxy_pass $ssl_preread_server_name:443;
        ssl_preread on;
    }
}
```

### Vergleich der Möglichkeiten

![Schaubild](../img/schaubild_cloudflare-vs-transparent-proxy.png){: loading=lazy }

Aus meiner Sicht ergibt die Verwendung eines eigenen
vorgeschaltenen Proxies nur Sinn, wenn mehr als ein Server
administriert wird und über eine IPv6 Adresse webbasierte
Dienste bereitstellt.

Wird lediglich ein System betreut (wie z.B. der oben erwähnte
Cloudserver), kann die zugewiesene IPv4 Adresse natürlich auf
den Ports 80 und 443 verwendet werden und dann auf den Reverse
Proxy zeigen. Dadurch entfällt die Abhängigkeit zu anderen Systemen.

Sofern der Cloudserver über keine eigene IPv4 Adresse oder keine
eigenen IPv6 Adressen verfügt, sollte ein Proxy vorgeschaltet werden,
um den Nutzern, die keine IPv4/IPv6 Adresse verfügen den Zugriff zu
ermöglichen.

Wird Cloudflare Proxy verwendet erkauft man sich neben der Erreichbarkeit
diverse Vorteile (DDoS Protection,
[Web Application Firewall](https://developers.cloudflare.com/waf/managed-rules/),
[Page Rules](https://www.cloudflare.com/features-page-rules/)).

Jedoch sollte man einige Details beachten, bevor man sich auf Cloudflare festlegt.
Der Datenverkehr der Nutzer liegt bei Cloudflare unverschlüsselt vor, da diese die
TLS Pakete terminieren. In der kostenfreien Version von Cloudflare Proxy können
des Weiteren keine gestackten Subdomains (`sub.sub.domain.de`) eingerichtet werden,
da dafür kein TLS Zertifikat angefordert werden kann.

### Reverse Proxy

Sowohl nginx, als auch Traefik, sind beide stark verbreitete Proxies. Sie werden von
großen Unternehmen wie Google, Cloudflare, Dropbox und Mozilla verwendet. Ich habe
mich nach reichlicher Überlegung dazu entschieden beide Varianten vorzustellen, da
sowohl Traefik, als auch nginx Vorteile hat.

!!! info ""
Hinsichtlich Traefik betrachten wir lediglich den dynamisches Modus,
bei dem das HTTP Routing über die Docker Labels konfiguriert wird.

Die Ersteinrichtung von Traefik empfinde ich, vor allem auf den ACME Client bezogen,
als schwieriger als die von nginx. Mit nginx wird acme.sh (ein separates Skript)
zum Ausstellen der TLS Zertifkate verwendet, während dies bei Traefik integriert ist.

Im weiteren Verlauf des Betriebs eines Systems mit Reverse Proxy bedeutet nginx einen
höheren Konfigurationsaufwand als Traefik, da die nginx Virtual Host Konfiguration anders
als bei Traefik nicht innerhalb der Containerdefinition erfolgt und die Zertifikate ggf.
manuell über acme.sh ausstellen werden müssen.

Traefik bringt des Weiteren ein Dashboard mit, welches einen komfortablen Überblick über
die existierenden Services und Router gibt. Dieses Dashboard sollte natürlich, sofern extern
erreichbar, entsprechend geschützt sein, um das ungewollte Leaken von Informationen zu vermeiden.

Einer der wichtigsten Aspekte für die Wahl des Reverse Proxies ist aber möglicherweise, dass
Traefik Zugriff auf den Docker Socket des Hosts benötigt, um die Container Labels auslesen zu können,
und die HTTP Routen dynamisch zu generieren. Im Falle einer Sicherheitslücke, bei der, der Traefik
Container übernommen werden kann, bedeutet dies, dass der gesamte Server komprimiert ist, da
beispielsweise ein neuer Container erstellt werden kann, bei dem das Host-Dateisystem komplett
eingehängt ist.

=== "nginx"
Da nginx nicht als Docker Container bereitgestellt wird, sondern direkt auf dem Host
installiert wird, gilt hier eine andere Verzeichnisstruktur.

    Die "Virtual-Host" Konfigurationsdateien liegen im Verzeichnis `/etc/nginx/sites-available/`
    unter der Domain, die Sie erreichbar machen.

    TLS Zertifikate beziehe ich mithilfe des Shellskriptes [`acme.sh`](https://github.com/acmesh-official/acme.sh), 
    welches ich unter dem root-Nutzer laufen lasse. Die resultierenden privaten Schlüssel 
    und Zertifkate werden im Verzeichnis `/root/.acme.sh/` gespeichert und direkt von 
    dort in der nginx Virtual-Host Konfiguration eingebunden.

=== "Traefik"
Da Traefik als Docker Container bereitgestellt wird, gilt die oben genannte Verzeichnisstruktur:

    * Containerdefinition: `/home/admin/traefik/docker-compose.yml`  
    * Env-Vars (hier DNS API Token): `/home/admin/traefik/.traefik.env`  
    * Daten (z.B. TLS Zertifikate): `/srv/traefik`  

    Traefik verwendet als ACME Client [Lego](https://go-acme.github.io/lego/). Die Konfiguration dieses 
    kann der [Traefik Dokumentation](https://doc.traefik.io/traefik/https/acme/) entnommen werden.
    Die angeforderten Zertifikate und Privaten Schlüssel werden im `/srv/traefik` Volume des Traefik 
    Containers gespeichert.

!!! note ""
In komplexeren Server-Infrastrukturen kann es sinnvoll sein, jedem Virtual Host eine
eigene dedizierte IPv6 Adresse zuzuweisen. Dies hat den großen Vorteil, das man z. B.
die Firewall Logs auf Layer 3 auswerten kann, statt den [TLS SNI Header](
https://en.wikipedia.org/wiki/Server_Name_Indication) zu betrachten um den beteiligten
Webserver in Erfahrung zu bringen.  
Da ich in diesen Netzwerken bisher immer auf nginx gesetzt habe,
habe ich nie geprüft, ob Traefik dieses Feature (jedem HTTP Router
eine eigene IPv6 Adresse zuzuweisen) ebenfalls unterstützt.

Prinzipiell ist die genutzte [ACME Challenge](https://letsencrypt.org/docs/challenge-types/) irrelevant, da ich
auch interne Dienste betreibe, die nicht aus dem Internet erreichbar sind, verwende ich prinzipiell die ACME-DNS-01
Challenge. Sowohl [Traefik / Lego](https://doc.traefik.io/traefik/https/acme/#providers) als auch
[`acme.sh`](https://github.com/acmesh-official/acme.sh/wiki/dnsapi) unterstützten eine Vielzahl an DNS API's
