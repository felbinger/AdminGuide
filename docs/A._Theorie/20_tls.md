# 2. TLS
Für die verschlüsselte Kommunikation zwischen Nutzer und Webserver sind TLS-Zertifikate
erforderlich.

In den Standard-Einstellungen von Betriebssystemen und Browsern ist bereits eine Auswahl
vertrauenswürdiger Zertifizierungsstellen (CAs) hinterlegt. Nur Zertifikate, die von einer
dieser anerkannten Stellen ausgestellt oder signiert wurden, werden vom Browser automatisch
als sicher bzw. vertrauenswürdig eingestuft. Diese sogenannte "Trusted Root Certificate Authority
List" wird von den jeweiligen Herstellern (z. B. Microsoft, Apple, Mozilla, Google) gepflegt und
regelmäßig aktualisiert.

Es gibt grundsätzlich drei Möglichkeiten, TLS-Zertifikate zu beziehen bzw. auszustellen:

1. **Kommerzielle Anbieter**

    Zertifikate können kostenpflichtig von anerkannten Zertifizierungsstellen wie DigiCert,
    GlobalSign oder GoDaddy erworben werden. Sie werden häufig von Unternehmen genutzt, um
    zusätzliche Garantieleistungen, erweiterte Validierungen (OV/EV) oder Supportleistungen
    zu erhalten.

2. **Kostenlose Zertifikate**

    Let’s Encrypt wurde 2015 von der gemeinnützigen Organisation Internet Security Research Group (ISRG)
    gegründet. Ziel war es, das Web durch die Bereitstellung kostenloser, automatisierter und durch offene
    Zertifikate sicherer zu gestalten und so verschlüsselte Verbindungen (HTTPS) zum Standard im Internet
    zu etablieren.

    Neben Let’s Encrypt existieren weitere Anbieter, die ähnliche kostenlose Zertifizierungsdienste anbieten,
    wie beispielsweise ZeroSSL und [Actalis](https://www.actalis.com/). Alle Anbieter unterstützen das
    ACME-Protokoll (Automatic Certificate Management Environment), über das die Ausstellung und Verlängerung
    von Zertifikaten automatisiert erfolgen kann.

    Diese kostenlosen Zertifikate sind von den gängigen Browsern als vertrauenswürdig anerkannt und eignen sich
    hervorragend für öffentliche Websites, Webanwendungen und APIs. Im Vergleich zu kommerziellen Angeboten bieten
    sie zwar keine zusätzlichen Garantieleistungen oder erweiterte Validierung (z. B. EV-Zertifikate), erfüllen
    aber auf technischer Ebene die selben Sicherheitsstandards.

3. **Eigene Zertifizierungsstelle (CA)**

    Neben öffentlichen und kommerziellen Anbietern besteht auch die Möglichkeit, eine eigene Zertifizierungsstelle
    (Certificate Authority, CA) zu betreiben. Damit können eigene Zertifikate ausgestellt werden – beispielsweise
    für interne Server, Entwicklungsumgebungen oder Testsysteme.

    Diese Variante ist kostenlos, erfordert jedoch mehr administrativen Aufwand. Damit Browser und Betriebssysteme
    den ausgestellten Zertifikaten vertrauen, muss das Root-Zertifikat der eigenen CA manuell auf allen beteiligten
    Geräten installiert werden. In kontrollierten Umgebungen (z. B. Firmennetzwerke oder geschlossene Systeme) kann
    dies automatisiert über zentrale Verwaltungswerkzeuge erfolgen.

    Für den produktiven Einsatz im öffentlichen Internet ist diese Lösung jedoch nicht geeignet, da externe Nutzer
    das Root-Zertifikat nicht installiert haben und der Browser die Verbindung daher als nicht vertrauenswürdig
    einstufen würde.

!!! warning
    Von der Verwendung selbstsignierter Zertifikate und dem Ignorieren von Browserwarnungen ist dringend abzuraten.

    Wer sich daran gewöhnt, Sicherheitsmeldungen einfach „wegzuklicken“, entwickelt schnell ein riskantes Verhalten.

Im Rahmen dieses Guides wird auf kostenlose TLS-Zertifikate des Anbieters Let’s Encrypt gesetzt.

Für die Verwaltung dieser stehen verschiedene Tools und Clients zur Verfügung. Wird nginx als Reverse Proxy
eingesetzt, bietet sich die Verwendung von [acme.sh](https://github.com/acmesh-official/acme.sh), ein schlanker,
in Shell geschriebener ACME-Client, der sich einfach in bestehende Umgebungen integrieren lässt, an.
Traefik hingegen verwendet für diesen Zweck standardmäßig den in Go entwickelten ACME-Client [Lego](https://go-acme.github.io/lego/).

Unabhängig von der gewählten Implementierung stehen bei Let’s Encrypt verschiedene [ACME-Challenge-Typen](https://letsencrypt.org/docs/challenge-types/)
zur Verfügung, über die die Domainvalidierung erfolgt.

Während die Challenge-Typen HTTP-01 und TLS-ALPN-01 voraussetzen, dass der Reverse Proxy aus dem Internet
erreichbar ist, bietet die DNS-01-Challenge die Möglichkeit, die Domainvalidierung über einen TXT-Eintrag
im DNS durchzuführen. Dadurch muss der Webserver nicht öffentlich zugänglich sein, und die ausgestellten
Zertifikate können somit auch in internen Umgebungen verwendet werden.
