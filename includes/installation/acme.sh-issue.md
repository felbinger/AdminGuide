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