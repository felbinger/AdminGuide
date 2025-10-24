# 1. Wahl des Reverse Proxies
Im Rahmen dieses Guides werden [nginx](https://www.nginx.com/) auf dem Host sowie
[Traefik](https://traefik.io/) als Container vorgestellt.

Nginx ist ein leistungsstarker und weit verbreiteter Webserver und Reverse Proxy, welcher sich
durch hohe Stabilität, Effizienz und Flexibilität in klassischen Serverumgebungen auszeichnet.

Traefik hingegen ist speziell auf containerisierte Umgebungen ausgelegt und integriert sich
nahtlos mit Plattformen wie Docker oder Kubernetes. Es erkennt neue Services automatisch und
konfiguriert Routing-Regeln dynamisch, was es besonders für moderne, dynamische Deployments
attraktiv macht.

!!! info "Nützliche Skripte: Verwendete Ports auflisten"

    Wenn man jedem Dienst eine eigene IPv6-Adresse zuweist, kann jeder Dienst nach Außen den gleichen
    Port verwenden (z. B. 443 für HTTPS). Auf dem Host müssen die Ports jedoch unterschiedlich sein.
    Um sich die verwendet Ports aller Dienste anzeigen zu lassen, kann folgender Befehl verwendet werden:
    `grep -oP "(?<=proxy_pass)[^;]*" /etc/nginx/sites-enabled/* | sed "s/ /\t/" | expand -t 30 | grep ${1:-.}`


    Wenn man diesen Befehl in eine Funktion schreibt und diese in die `.bashrc` einfügt, kann man nach
    der Verwendung eines genauen Ports suchen:
    ```bash
    function searchport {
      grep -oP "(?<=proxy_pass)[^;]*" /etc/nginx/sites-enabled/* | sed "s/ /\t/" | expand -t 30 | grep ${1:-.}
    }
    ```

    Verwendung: `searchport 8080` -> Listet alle Dienste auf, die den Port 8080 verwenden.
