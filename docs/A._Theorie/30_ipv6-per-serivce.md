# 3. Eine IPv6 Adresse pro Service

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


## Useful Scripts

### IPv6 Adresse generieren
!!! note
    Dieses Skript erzeugt jediglich eine neue IPv6-Adresse! Diese wird nicht automatisch dem 
    Netzwerkinterface hinzugefügt. Dies muss separat erfolgen!

Das erstellen einer neuen IPv6 Adresse aus dem /64 Präfix des Servers kann mit folgendem simplen
Skript automatisiert werden:

```bash
#!/bin/bash

v=$(cat /dev/urandom | tr -dc a-f0-9 | fold -w16 | head -n1)
echo  your:first:four:blocks:${v:0:4}:${v:4:4}:${v:8:4}:${v:12}
```

Die ersten vier Blöcke der IPv6-Adresse (`your:first:four:blocks`) müssen dabei durch das
jeweilige /64-Präfix des Servers ersetzt werden (Bsp.: `2001:0db8:85a3:0053`).


### Verwendete Ports auflisten
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