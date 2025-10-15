# Theoretische Grundlagen

## Wahl des Reverse Proxies
Im Rahmen dieses Guides werden nginx auf dem Host sowie Traefik als Container vorgestellt.

Nginx ist ein leistungsstarker und weit verbreiteter Webserver und Reverse Proxy, der sich
durch hohe Stabilität, Effizienz und Flexibilität in klassischen Serverumgebungen auszeichnet.

Traefik hingegen ist speziell auf containerisierte Umgebungen ausgelegt und integriert sich
nahtlos mit Plattformen wie Docker oder Kubernetes. Es erkennt neue Services automatisch und
konfiguriert Routing-Regeln dynamisch, was es besonders für moderne, dynamische Deployments
attraktiv macht.

## Eine IPv6 Adresse pro Service

!!! note
    Die meisten Hosting-Provider weisen jedem Server ein /64-IPv6-Präfix zu,
    was einem Adressraum von $2^{64}$ Adressen entspricht – eine Zahl, die in
    der Praxis quasi unerschöpflich ist.

    Ausnahmen gibt es beispielsweise bei Strato: Dort wird nicht ein ganzes /64-IPv6-Präfix,
    sondern lediglich eine einzelne IPv6-Adresse pro Server zugewiesen. Dadurch ist es nicht
    möglich, jedem Dienst eine eigene IPv6-Adresse zu geben
    ([siehe YouTube Short](https://www.youtube.com/shorts/oSvU4HXZ_Wc)).

Wird jedem nginx Reverse Proxy eine eigene IPv6-Adresse zugewiesen, kann bereits auf OSI-Layer 3
nachvollzogen werden, an welchen Webservice eine Anfrage gerichtet war. Würde hingegen für alle
Dienste nur eine gemeinsame Adresse verwendet, wäre eine eindeutige Zuordnung frühestens auf
Layer 5 (durch Auswertung des TLS SNI Headers) möglich; ohne ein spezielles Analysewerkzeug sogar
erst auf Layer 7, etwa über die Logdaten des Webservers.

Der Webserver nginx bietet mit der Direktive `listen` die Möglichkeit, virtuelle Hosts an spezifische
IPv4- oder IPv6-Adressen zu binden. Diese Technik erlaubt eine frühzeitige Trennung und Zuordnung des
eingehenden Traffics zu den einzelnen Anwendungen. Soll ein Dienst abgeschaltet oder vorübergehend
blockiert werden, kann dessen zugewiesene Adresse zudem sehr einfach über die Firewall – oder sogar
direkt beim Provider – gesperrt werden, ohne dass Änderungen an der Servicekonfiguration selbst
erforderlich sind.

## Sonderfälle
### Virtualisierungsserver
Zwar richtet sich dieser Guide in erster Linie an Administratoren einfacher vServer, doch kann es
schnell vorkommen, dass aufgrund steigender Leistungsanforderungen auf einen dedizierten Server
gewechselt wird.

Nehmen wir an, ein solcher Server verfügt über eine IPv4-Adresse und ein /64-IPv6-Präfix, auf dem
mehrere virtuelle Maschinen betrieben werden sollen. Das Hostsystem, das direkt auf der physischen
Hardware installiert ist, kann in diesem Szenario als Router fungieren. Über NAT und Port Address
Translation (PAT) lassen sich dabei gezielt einzelne Ports an die virtualisierten Systeme weiterleiten.

Dank des zugewiesenen IPv6-Präfixes kann jedoch jeder virtuellen Maschine eine eigene öffentliche
IPv6-Adresse zugeordnet werden, wodurch sie direkt aus dem Internet erreichbar ist – ganz ohne NAT.

In diesem Zusammenhang kann der Einsatz eines IPv4-zu-IPv6-Proxys sinnvoll sein. Ein solcher Proxy
nimmt Anfragen über IPv4 entgegen und leitet sie intern per IPv6 an den Zielserver weiter. Auf diese
Weise bleibt die Erreichbarkeit auch für IPv4-Clients gewährleistet, selbst wenn die eigentliche
Infrastruktur ausschließlich auf IPv6 basiert.

### IPv6-only Server
Angenommen, es steht eine größere Anzahl von Servern zur Verfügung. Um Kosten und Verwaltungsaufwand
zu reduzieren, wird dabei bewusst auf individuelle IPv4-Adressen verzichtet und jedem System ausschließlich
ein IPv6-Netz zugewiesen.

!!! warning
    Dieses Setup impliziert, dass die Systeme selbst keine ausgehende IPv4-Verbindung aufbauen können.
    Das kann die Administration erschweren – beispielsweise, wenn Repositories von GitHub, Docker Hub oder
    anderen ausschließlich über IPv4 erreichbaren Diensten bezogen werden sollen. In solchen Fällen ist
    entweder ein IPv6-fähiger Mirror oder ein NAT64-Gateway erforderlich, um den Zugriff zu ermöglichen.

    Die wenigsten Anbieter stellen derzeit NAT64 Gateways zur Verfügung, weshalb zum derzeitigen Zeitpunkt
    von dieser Systemarchitektur abzuraten ist.

Die Erreichbarkeit dieser Server aus dem IPv4-Internet kann in einem solchen Szenario über einen zentralen
IPv4-zu-IPv6-Proxy sichergestellt werden. Dieser Proxy fungiert als gemeinsame Eingangsstelle für alle
IPv4-Anfragen und leitet sie intern über IPv6 an die jeweiligen Zielsysteme weiter – effizient, kostensparend
und ohne die Notwendigkeit zusätzlicher IPv4-Ressourcen.

## IPv4-to-IPv6 Proxy
Zur Vereinfachung der vorgestellten Sonderfälle kann folgende einfache nginx Konfiguration verwendet werden.
Diese implementiert einen IPv4-to-IPv6 Proxy, der zwar in dieser Version lediglich HTTP- und HTTPs-Verbindungen
unterstützt, jedoch mit geringfügigen Anpassungen auch für andere TLS-gesicherte Protokolle wie SMTPs, IMAPs
oder POP3s verwendet werden kann.

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
