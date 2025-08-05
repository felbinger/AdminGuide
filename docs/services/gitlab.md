# GitLab

GitLab ist eine Software für Code-Management und Versionierung. Außerdem bietet es eine Vielzahl an Tools für die
Zusammenarbeit in Teams wie Issue-Tracking, CI/CD-Pipelines und Wikis.

```yaml
services:
  gitlab:
    image: 'gitlab/gitlab-ce'
    restart: always
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://git.domain.de'
        letsencrypt['enable'] = false
    ports:
      - "[::1]:8000:80"
    volumes:
      - "/srv/gitlab/config:/etc/gitlab"
      - "/srv/gitlab/logs:/var/log/gitlab"
      - "/srv/gitlab/data:/var/opt/gitlab"
```

=== "nginx"
    ```yaml
        ports:
          - "[::1]:8000:80"
    ```

    ```nginx
    # /etc/nginx/sites-available/gitlab.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.27.3&config=modern&openssl=3.4.0&ocsp=false&guideline=5.7
    server {
        server_name gitlab.domain.de;
        listen 0.0.0.0:443 ssl http2;
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/gitlab.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/gitlab.domain.de_ecc/gitlab.domain.de.key;
        ssl_session_timeout 1d;
        ssl_session_cache shared:MozSSL:10m;  # about 40000 sessions
        ssl_session_tickets off;

        # modern configuration
        ssl_protocols TLSv1.3;
        ssl_prefer_server_ciphers off;

        # HSTS (ngx_http_headers_module is required) (63072000 seconds)
        add_header Strict-Transport-Security "max-age=63072000" always;

        # OCSP stapling
        ssl_stapling on;
        ssl_stapling_verify on;

        location / {
            proxy_pass http://[::1]:8000/;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection 'upgrade';
            proxy_set_header X-Real-IP $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-For $remote_addr;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_set_header Host $host;
            proxy_cache_bypass $http_upgrade;
        }
    }
    ```

=== "Traefik"
    ```yaml
        labels:
          - "traefik.enable=true"
          - "traefik.http.services.srv_gitlab.loadbalancer.server.port=80"
          - "traefik.http.routers.r_gitlab.rule=Host(`gitlab.domain.de`)"
          - "traefik.http.routers.r_gitlab.entrypoints=websecure"
    ```

!!! info ""
    Die `external_url` muss `http://...` sein wenn man einen reverse proxy verwendet, welcher TLS verarbeitet. Andererseits
    würde GitLab versuchen die anfragen von einem Benutzer auf https weiterzuleiten und diesen würde in einem unendlichen
    Weiterleitungskreis enden.

## Mailserver
Um einen Mailserver einzurichten, muss man nur diese wenigen einfachen Konfigurationsoptionen zu der
GITLAB_OMNIBUS_CONFIG Environment variable hinzufügen

```shell
        gitlab_rails['gitlab_email_enabled'] = true
        gitlab_rails['gitlab_email_from'] = 'gitlab@domain.de'
        gitlab_rails['gitlab_email_display_name'] = 'gitlab@domain.de'
        gitlab_rails['gitlab_email_reply_to'] = 'gitlab@domain.de'
        gitlab_rails['smtp_enable'] = true
        gitlab_rails['smtp_address'] = 'gitlab@domain.de'
        gitlab_rails['smtp_port'] = 587
        gitlab_rails['smtp_user_name'] = 'gitlab@domain.de'
        gitlab_rails['smtp_password'] = 'S3cr3T'
        gitlab_rails['smtp_domain'] = 'smtp.domain.de'
        gitlab_rails['smtp_authentication'] = 'login'
        gitlab_rails['smtp_enable_starttls_auto'] = true
		gitlab_rails['gitlab_root_email'] = 'admin@domain.de'
```

## OpenID / Keycloak

Die Einrichtung von OIDC mit Keycloak ist genauso einfach. Auch hier einfach folgende Attribute zu der
GITLAB_OMNIBUS_CONFIG environment Variable hinzufügen.

```shell
        gitlab_rails['omniauth_enabled'] = true
        gitlab_rails['omniauth_block_auto_created_users'] = false
        gitlab_rails['omniauth_allow_single_sign_on'] = ['oauth2_generic']
        gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'oauth2_generic'
        gitlab_rails['omniauth_providers'] = [
          {
            "name" => "oauth2_generic",
            "app_id" => "gitlab.domain.de",
            "app_secret" => "",
            'args' => {
              client_options: {
                'site' => 'https://id.domain.de',
                'user_info_url' => '/realms/main/protocol/openid-connect/userinfo',
                'authorize_url' => '/realms/main/protocol/openid-connect/auth',
                'token_url' => '/realms/main/protocol/openid-connect/token'
              },
              user_response_structure: {
                 id_path: ['sub'],
                 attributes: { username: 'username'}
              }
            },
            'redirect_uri' =>  'https://gitlab.domain.de/users/auth/oauth2_generic/callback'
          }
        ]
        gitlab_rails['omniauth_allow_bypass_two_factor'] = ["oauth2_generic"]
```