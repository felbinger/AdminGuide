# 6. Cloudflare API Token erstellen

Um die DNS-01 Challenge für die SSL-Zertifikate lösen zu können, benötigen wir einen API Token von Cloudflare.

Zum erstellen des API Tokens meldet man sich bei Cloudflare an und befolgt folgende Schritte:


## Navigiere zu "My Profile" und öffne den Reiter "API Tokens"

![Cloudflare My Profile](../img/cloudflare/path_to_API_Token_setting.png)


## Nach dem Klick auf "Create Token" das "Edit zone DNS" Template auswählen

![Cloudflare Create API Token](../img/cloudflare/zone_dns_template.png)


## Token konfigurieren

[//]: # (TODO Frage: Namensgebung des Tokens vorschläge geben?)
1. In der ersten roten Markierung den Namen für das Token vergeben.
2. In der zweiten roten Markierung die Zone auswählen, für welche der Token gültig sein soll (können auch mehrere sein).
3. In der dritten roten Markierung die IP Adressen des Server eintragen, welche den Token verwenden dürfen.
-> Dort bietet sich an einerseits das IPv6 Subnet und andererseits die IPv4 Adresse einzutragen.

![Cloudflare Configure API Token](../img/cloudflare/create_token_window.png)
