bookstack: saml
gitlab: oidc + config from below
jitsi
matrix
openvpn
sentry
ADD .well-known
PR Matrix


#external_url 'https://git.secshell.de'
letsencrypt['enable'] = false
gitlab_rails['gitlab_shell_ssh_port'] = 2222
gitlab_rails['gitlab_email_enabled'] = true
gitlab_rails['gitlab_email_from'] = 'noreply@secshell.de'
gitlab_rails['gitlab_email_display_name'] = 'gitlab@secshell.de'
gitlab_rails['gitlab_email_reply_to'] = 'admin@secshell.de'
gitlab_rails['smtp_enable'] = true
gitlab_rails['smtp_address'] = 'noreply@secshell.de'
gitlab_rails['smtp_port'] = 587
gitlab_rails['smtp_user_name'] = 'noreply@secshell.de'
gitlab_rails['smtp_password'] = ''
gitlab_rails['smtp_domain'] = 'mail.your-server.de'
gitlab_rails['smtp_authentication'] = 'login'
gitlab_rails['smtp_enable_starttls_auto'] = true
gitlab_rails['gitlab_root_email'] = 'admin@secshell.de'
gitlab_rails['omniauth_enabled'] = true
gitlab_rails['omniauth_block_auto_created_users'] = false
gitlab_rails['omniauth_allow_single_sign_on'] = ['oauth2_generic']
gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'oauth2_generic'
gitlab_rails['omniauth_providers'] = [
  {
    "name" => "oauth2_generic",
    "app_id" => "gitlab.pve2.secshell.net",
    "app_secret" => "",
    'args' => {
      client_options: {
        'site' => 'https://id.secshell.de',
        'user_info_url' => '/realms/main/protocol/openid-connect/userinfo',
        'authorize_url' => '/realms/main/protocol/openid-connect/auth',
        'token_url' => '/realms/main/protocol/openid-connect/token'
      },
      user_response_structure: {
         id_path: ['sub'],
         attributes: { username: 'username'}
      }
    },
    'redirect_uri' =>  'https://git.secshell.de/users/auth/oauth2_generic/callback'
  }
]
gitlab_rails['omniauth_allow_bypass_two_factor'] = ["oauth2_generic"]