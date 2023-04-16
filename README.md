# Admin Guide
You can find this repository here: [https://adminguide.pages.dev](https://adminguide.pages.dev).

## Contribute
Feel free to open issues / pull requests.  
Please validate that your changes work as intented!  
You can start the mkdocs development server by running:
```bash
sudo ./serve.sh
# or
sudo sh ./serve.sh
```
The http server is then listening on port 8000.  
**Please review every script from the Internet before executing it!**

### Contribution Guidelines
* Web Services are exposed to `[::1]:8000`
* Secret Environment Variables are in an env_file (and not in the `docker-compose.yml` itself, to prevent leaks) with the following format:
  ```shell
  # .servicename.env
  KEY=value
  ```
* environment variables should be in form of a YAML array, not an object:
  ```yaml
  environment:
    - "KEY=value"
  ```
  instead of
  ```yaml
  # WRONG - please don't do this
  environemnt:
    KEY: value
  # WRONG
  ```
* If possible the service should use either mariadb or postgresql.
  If it makes sense, other databases (e.g. sqlite) are also quiet fine.
* YAML arrays should be quoted, regardless which data is stored:
  ```yaml
  volumes:
    - "/srv/service_name/data:/data"
  ports:
    - "[::1]:8000:1234"
  networks:
    - "default"
    - "database"
  ```

## TODO
* Can traefik assign each http router a seperate ipv6 address?
* How to configure authenticated origin pulls with traefik and cloudflare?
* Describe how we can give traefik a origin server wildcard tls certificate, instead of using ACME with LEGO.
* Test the trafik setup - I wrote it from what I remembered last time doing it...
* Think about splitting the three [traefik container definition](./docs/Installation/) into seperate files (to avoid duplicate configuration fragments).

### Services
* Add reverse proxy setup instructions according to template.

#### Rewrite required:
* Sentry - or remove!
* Prometheus
* Netbox
* Matrix (Federations, Bridges, ...)
* Jitsi
* Guacamole OIDC Integration (doesn't work like this...)
* Grafana (configure ldap and oidc using environment files, not via config; external database)
* Gitea (OIDC)
* Bookstack (SAML)

#### Test if still working
* Typo 3 - remove if not
* Seafile
* Privatebin
* OpenVPN - remove if not
* OpenLDAP - remove if not
* Jupyter
* Gitlab
* docky-onion - remove if not
