# TL;DR

## Wahl des Reverse Proxies
Docker Container bringen oft keine Möglichkeit mit verschlüsselte Anfragen zu verarbeiten.
Des Weiteren könnten wir jeden Port nur einmal auf jeder IPv4 / IPv6 Adresse verwenden.

Abhilfe schafft dabei ein Reverse Proxy, der die externen Anfragen verarbeitet und an den
richtigen Container leitet. Als Reverse Proxy kann [nginx](https://www.nginx.com/) direkt
auf dem Host oder [Traefik](https://traefik.io/) als eigenständiger Container verwendet werden.

## TLS
Es werden kostenlose TLS Zertifikate von [Let's Encrypt](https://letsencrypt.org/) verwendet.

Als Zertifikatsverwaltungsoftware dient

- [acme.sh](https://github.com/acmesh-official/acme.sh), sofern nginx als Reverse Proxy verwendet wird, und
- [Lego](https://go-acme.github.io/lego/) wenn Wahl auf Traefik gefallen ist.

Es wird die ACME-DNS-01 Challenge verwendet, da die Erreichbarkeit des Reverse Proxies
aus dem Internet nicht erforderlich ist und somit auch für interne Dienste (z. B. ein
Homelab) nutzbar ist.

## Eine IPv6 Adresse pro Service
Die meisten Server erhalten vom Provider ein öffentliches /64er IPv6 Präfix.
Das sind in der Praxis einer unerschöpflichen Anzahl an Adressen,
daher erhält jeder Service eine eigene Adresse für eingehende Anfragen.

Dies ermöglicht beispielsweise das blockieren eines Services über die
Firewall des Hosters, ohne dass der Server verändert werden muss
(z. B. von unterwegs).

## IPv4 to IPv6 Proxy
Hast du einen Dedizierten Server, auf dem du virtualisierst und somit mehrere virtuelle
Maschinen, die über eine IPv4 Adresse mit dem Internet kommunizieren? Oder hast du vielleicht
mehrere Server, von denen manche aus kostengründen lediglich über eine IPv6 Adresse verfügen?

Mit einem einfachen Proxy Server besteht die Möglichkeit Nutzer, die sich über IPv4 mit dem Dienst
verbinden auf einen IPv6-only Server weiterzuleiten. Auch dein dedizierter Server, auf dem du
virtualisierst hat ein /64 IPv6 Präfix, daher kannst du jeder VM (oder in Kombination mit dem
vorherigen Konzept) jedem Dienst eine eigene öffentlich IPv6 Adresse geben.

## Interne Netzwerke
Werden mehrere Dienste gehostet, ergeben sich oft gleiche Anforderungen (z. B. 3x MariaDB).

Um Resourcen zu sparen kann eine zentrale Datenbank erstellt werden, die von allen Diensten
genutzt werden soll. Um diese nicht offen ins Internet zu hängen, wird diese über ein eigenes
Docker Netzwerk als interner Dienst angeboten.
