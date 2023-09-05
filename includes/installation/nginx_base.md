
Kostenlose TLS Zertifikate können über Anbieter wie ZeroSSL 
oder Let's Encrypt bezogen werden. In unserem Fall beziehen wir diese von Let's Encrypt mithilfe von
[acme.sh](https://github.com/acmesh-official/acme.sh).

```shell
# mit root-Rechten ausführen
apt install nginx-full

# acme.sh installieren und default ca auf Let's Encrypt setzen
curl https://get.acme.sh | sh -s email=acme@domain.de
ln -s /root/.acme.sh/acme.sh /usr/bin/acme.sh
acme.sh --install-cronjob

acme.sh --server "https://acme-v02.api.letsencrypt.org/directory" --set-default-ca
```

{% include-markdown "../../includes/installation/nginx-multiple-ipv6.md" %}


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

{% include-markdown "../../includes/installation/local-port-binding.md" %}

### TLS Zertifkat über acme.sh anfordern

Für acme.sh müssen die erforderlichen Umgebungsvariablen für die gewünschte 
[ACME Challenge](https://letsencrypt.org/docs/challenge-types/) gesetzt 
sein. Für die DNS API's der Anbieter empfielt sich ein Blick in 
[diese Tabelle](https://github.com/acmesh-official/acme.sh/wiki/dnsapi).

```shell
# Beispielkonfiguration für Cloudflare DNS API
export CF_Account_ID=
export CF_Zone_ID=
export CF_Token=
acme.sh --issue --keylength ec-384 --dns dns_cf -d service.domain.de
```

{% include-markdown "../../includes/installation/additional_ipv6.md" %}
