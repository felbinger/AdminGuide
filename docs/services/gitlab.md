### Check out the [Official Guide](https://docs.gitlab.com/omnibus/docker/).

Setting up Gitlab
==================

Setting up Gitlab with Docker-Compose isn't really that hard. Look at this Example:

```
  gitlab:
    image: 'gitlab/gitlab-ce:latest'
    restart: always
    environment:
      GITLAB_OMNIBUS_CONFIG: |
        external_url 'http://gitlab.example.com'
    labels:
      - "traefik.enable=true"
      - "traefik.http.services.srv_gitlab.loadbalancer.server.port=80"
      - "traefik.http.routers.r_gitlab.rule=Host(`gitlab.example.com`)"
      - "traefik.http.routers.r_gitlab.entrypoints=websecure"
      - "traefik.http.routers.r_gitlab.tls=true"
      - "traefik.http.routers.r_gitlab.tls.certresolver=myresolver"
    volumes:
      - 'gitlab-config:/etc/gitlab'
      - 'gitlab-logs:/var/log/gitlab'
      - 'gitlab-data:/var/opt/gitlab'
```

**It is very important to use the http protocol in the `external_url` variable instead of using https if you
are running Gitlab behind a reverse Proxy handling SSL/TLS for you (like Traefik).**

If you use https inside the Variable Gitlab will try to enforce https Connections and reject the http Connections from
Traefik, which will result in a never ending redirect Cycle.    

You should now be able to reach Gitlab under your given Domain and create the initial Administrator Account.

Configuring SSO with OAuth2
===========================

To configure external Authentication Gitlab's Config must be edited.

Enter the Container with `docker-compose exec gitlab bash` and edit the file `/etc/gitlab/gitlab.rb` with
an Editor of your Choice.

Search for the Section `### Omniauth Settings` and uncomment / add and edit the following lines:

```
gitlab_rails['omniauth_enabled'] = true
gitlab_rails['omniauth_allow_single_sign_on'] = ['oauth2_generic']
gitlab_rails['omniauth_block_auto_created_users'] = false

gitlab_rails['omniauth_providers'] = [
  {
    "name" => "oauth2_generic",
    "app_id" => "YOURID",
    "app_secret" => "YOURSECRET",
    'args' => {
      client_options: {
        'site' => 'YOURPROVIDER',
        'user_info_url' => 'PROVIDERUSERINFO',
        'authorize_url' => 'PROVIDERAUTH',
        'token_url' => 'PROVIDERTOKEN'
      },
      user_response_structure: {
         id_path: ['sub'],
         attributes: { username: 'username'}
      } },
    'redirect_uri' =>  'https://gitlab.YOURDOMAIN.com/users/auth/oauth2_generic/callback'
  }
]
```

Replace the Values written in CAPS with those provided by your Authentication Service. Depending on your
Authentication Service it might be necessary to change the `user_response_structure`.

Now save, exit the Editor and execute following Command: `gitlab-ctl reconfigure`. You should now
see an additional Login Button at your Login Page which will take you directly to your Authentication Service.

If everything works, your Authentication Service should log you into Gitlab.

You can now additionally add the following line to your `gitlab.rb` File:

```
gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'oauth2_generic'
```

This will tell Gitlab to skip its own Login Page and instantly redirect you to your Authentication Service.
Prior to doing this you should either make an SSO-Account Administrator oder link an SSO-Account to the initial
Administrator Account as you will no longer be able to log in with the initial Administrator the regular way.

If something goes wrong the Gitlab-Logs and the Messages from your Authentication Service should be helpful to you.
Furthermore you can refer to [this Documentation](https://docs.gitlab.com/ee/integration/oauth2_generic.html) 
from Gitlab itself.

Configuring SSO with Keycloak
=============================

If you use your own *Keycloak* Instance as an Authentication Service you have to configure Keycloak properly.

At first, create a new Client. **The Client ID must be the Domain of your Gitlab.** The Client Protocol is
*openid-connect*.

Now edit the new Client. Leave all Settings standard except of the following:

Setting | Value
--------|-------
Root URL | `https://gitlab.example.com/`
Valid Redirect URIs | `https://gitlab.example.com/*` <br /> `http://gitlab.example.com/*`
Base URL | `https://gitlab.example.com/`
Web Origins | +


**It is very important to specify both http and https under `Valid Redirect URIs`, or the Authentication Process
won't work.**

Save the Settings. You can now copy your Client Secret from the "Credentials" Tab.

Now you need to edit your `gitlab.rb` File. For Keycloak it should look like this:

```
gitlab_rails['omniauth_enabled'] = true
gitlab_rails['omniauth_allow_single_sign_on'] = ['oauth2_generic']
# gitlab_rails['omniauth_auto_sign_in_with_provider'] = 'oauth2_generic' # (Uncomment if you finished Testing)
gitlab_rails['omniauth_block_auto_created_users'] = false

gitlab_rails['omniauth_providers'] = [
  {
    "name" => "oauth2_generic",
    "app_id" => "gitlab.example.com",
    "app_secret" => "YOURSECRET",
    'args' => {
      client_options: {
        'site' => 'https://keycloak.example.com/',
        'user_info_url' => '/auth/realms/YOURREALM/protocol/openid-connect/userinfo',
        'authorize_url' => '/auth/realms/YOURREALM/protocol/openid-connect/auth',
        'token_url' => '/auth/realms/YOURREALM/protocol/openid-connect/token'
      },
      user_response_structure: {
         id_path: ['sub'], 
         attributes: { username: 'username'}
      } },
    'redirect_uri' =>  'https://gitlab.YOURDOMAIN.com/users/auth/oauth2_generic/callback'
  }
]
```

Now run `gitlab-ctl reconfigure`. You should be now be able to login using your Keycloak Accounts.