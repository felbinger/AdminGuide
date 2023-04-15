
{% include-markdown "acme.sh-nginx-install.md" %}

{% include-markdown "nginx-multiple-ipv6.md" %}

## Konfiguration für neue Dienste

Folgende Schritte sind notwendig, um ein neues HTTP Routing zu konfigurieren:
1. Dienst aufsetzen.
2. Port-Binding von Dienst auf IPv6 Localhost (`::1`) des Hosts.
3. TLS Zertifkat über acme.sh anfordern.
4. Optional: Eigene IPv6 Adresse für Virtual Host konfigurieren.
5. nginx Virtual-Host konfigurieren und aktivieren.
6. Konfiguration testen und nginx neu laden.

### Dienst aufsetzen
...


{% include-markdown "local-port-binding.md" %}

{% include-markdown "acme.sh-issue.md" %}

{% include-markdown "additional_ipv6.md" %}
