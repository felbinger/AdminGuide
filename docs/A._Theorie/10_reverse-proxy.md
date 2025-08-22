# 1. Wahl des Reverse Proxies
Im Rahmen dieses Guides werden [nginx](https://www.nginx.com/) auf dem Host sowie
[Traefik](https://traefik.io/) als Container vorgestellt.

Nginx ist ein leistungsstarker und weit verbreiteter Webserver und Reverse Proxy, welcher sich
durch hohe Stabilität, Effizienz und Flexibilität in klassischen Serverumgebungen auszeichnet.

Traefik hingegen ist speziell auf containerisierte Umgebungen ausgelegt und integriert sich
nahtlos mit Plattformen wie Docker oder Kubernetes. Es erkennt neue Services automatisch und
konfiguriert Routing-Regeln dynamisch, was es besonders für moderne, dynamische Deployments
attraktiv macht.
