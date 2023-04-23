# GitLab

GitLab ist eine Software für Code-Management und Versionierung. Außerdem bietet es eine Vielzahl an Tools für die
Zusammenarbeit in Teams wie Issue-Tracking, CI/CD-Pipelines und Wikis.

```yaml
version: '3.9'

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
=== "Traefik"
    ```yaml
        labels:
          - "traefik.enable=true"
          - "traefik.http.services.srv_gitlab.loadbalancer.server.port=80"
          - "traefik.http.routers.r_gitlab.rule=Host(`gitlab.domain.de`)"
          - "traefik.http.routers.r_gitlab.entrypoints=websecure"
    ```

!!! info ""
	The `external_url` has to be `http://...` when using a reverse proxy which handles tls, otherwise gitlab tries
    to redirect the incoming http connection to https which ends in a never ending redirect cycle.

## Mailserver
The setup of a mailserver is quite simple, simply add the following configuration options 
to the GITLAB_OMNIBUS_CONFIG environment variable:  
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

# OpenID / Keycloak
The setup of OIDC with keycloak is also quite simple, simply add the following configuration options 
to the GITLAB_OMNIBUS_CONFIG environment variable:  
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