# docky-onion

!!! warning ""
	This Admin Guide is being rewritten at the moment!



To provide [tor hidden services](https://2019.www.torproject.org/docs/onion-services) through docker you can use [docky-onion](https://github.com/use-to/docky-onion) to make any of your services accessible through [tor](https://www.torproject.org/). Here is an example `docker-compose.yml` to serve an [nginx](https://www.nginx.com/) as hidden service on port `80` and `8080`:

```yaml
version: "3.9"

services:
  docky-onion:
    image: useto/docky-onion
    restart: always
    environment:
      # this forwards 80 and 8080 to web:80
      - "TOR_HIDDEN_SERVICE_WEB=80 web:80;8080 web:80"
    volumes:
      - "docky-onion:/var/lib/tor/hidden_services"

  web:
    image: nginx
    restart: always
    depends_on:
      - docky-onion 

volumes:
  docky-onion:
```

After you start the containers using `docker-compose up -d` docky-onion will proxy nginx into the tor network. Now we need to lookup the `.onion`-address using `docker-compose exec docky-onion lookup`. This will print something like the following:

```
WEB => j3c7wmyv6b3q3uvowetwwygb7h57k2bjhtnwp2zfamda2ij2vanyhmid.onion
```

Please note that you will get multiple `.onion`-address for each service you want to serve.
