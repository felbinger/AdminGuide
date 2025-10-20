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
