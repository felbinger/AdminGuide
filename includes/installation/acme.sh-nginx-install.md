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