# Psono

Psono ist ein self-hosted open source passwort manager. Er auf einfache User Erfahrung optimiert und ist sehr simpel
aufzusetzen und zu konfigurieren.


```yaml
services:
  postgres:
    restart: always
    image: postgres:13-alpine
    env_file: .postgres.env
    environment:
      POSTGRES_USER: psono
    volumes:
      - "/srv/psono/postgres:/var/lib/postgresql/data"

  psono-combo:
    image: psono/psono-combo:latest
    restart: always
    ports:
      - "[::1]:8000:80"
    command: sh -c "sleep 5 && /bin/sh /root/configs/docker/cmd.sh"
    volumes:
      - /srv/psono/data/settings.yaml:/root/.psono_server/settings.yaml
      - /srv/psono/client/config.json:/usr/share/nginx/html/config.json
      - /srv/psono/client/config.json:/usr/share/nginx/html/portal/config.json
    sysctls:
      - net.core.somaxconn=65535
```

```shell
# .postgres.env
POSTGRES_PASSWORD=S3cr3t
```

=== "nginx"
    ```yaml
    ports:
      - "[::1]:8000:80"
    ```

    ```nginx
    # /etc/nginx/sites-available/psono.domain.de
    # https://ssl-config.mozilla.org/#server=nginx&version=1.17.7&config=modern&openssl=1.1.1d&guideline=5.6
     
    server {
        server_name psono.domain.de;
        listen 0.0.0.0:443 ssl http2
        listen [::]:443 ssl http2;

        ssl_certificate /root/.acme.sh/passbolt.domain.de_ecc/fullchain.cer;
        ssl_certificate_key /root/.acme.sh/passbolt.domain.de_ecc/passbolt.domain.de.key;
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

        add_header Referrer-Policy same-origin;
        add_header X-Frame-Options DENY;
        add_header X-Content-Type-Options nosniff;
        add_header X-XSS-Protection "1; mode=block";
    
        # If you have the fileserver too, then you have to add your fileserver URL e.g. https://fs01.example.com as connect-src too:
        add_header Content-Security-Policy "default-src 'none';  manifest-src 'self'; connect-src 'self' https://static.psono.com https://api.pwnedpasswords.com https://storage.googleapis.com https://*.digitaloceanspaces.com https://*.blob.core.windows.net https://*.s3.amazonaws.com; font-src 'self'; img-src 'self' data:; script-src 'self'; style-src 'self' 'unsafe-inline'; object-src 'self'; child-src 'self'";
    
        client_max_body_size 256m;
    
        gzip on;
        gzip_disable "msie6";
    
        gzip_vary on;
        gzip_proxied any;
        gzip_comp_level 6;
        gzip_buffers 16 8k;
        gzip_http_version 1.1;
        gzip_min_length 256;
        gzip_types text/plain text/css application/json application/x-javascript application/javascript text/xml application/xml application/xml+rss text/javascript application/vnd.ms-fontobject application/x-font-ttf font/opentype image/svg+xml image/x-icon;

        location / {
           proxy_pass http://[::1]:8000/;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_http_version 1.1;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header Host $http_host;
           proxy_set_header Connection "Upgrade";
           proxy_set_header Upgrade $http_upgrade;
           proxy_set_header X-Nginx-Proxy true;
           proxy_set_header X-Forwarded-Proto $scheme;      
        }
        
        location ~* \.(?:ico|css|js|gif|jpe?g|png|eot|woff|woff2|ttf|svg|otf)$ {
            proxy_pass http://[::1]:8000;
            expires 30d;
            add_header Pragma public;
            add_header Cache-Control "public";
            proxy_set_header Host $host;
            proxy_set_header X-Real-IP $remote_addr;
            proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
            proxy_set_header X-Forwarded-Proto $scheme;
            proxy_hide_header Content-Security-Policy;
        }
    }
    ```


=== "Traefik"
    Coming Soon...



### Serverkeys erstellen
```shell
docker run --rm -ti psono/psono-combo:latest python3 ./psono/manage.py generateserverkeys
```

Die Ausgabe des Befehls temporär zwischenspeichern. Diese wird für den nächsten Schritt benötigt.


### Erstelle `settings.yaml` in `/srv/psono/data/settings.yaml`
```yaml
# Replace the keys below with the one from the generateserverkeys command.
SECRET_KEY: 'SECRET_KEY_FROM_COMMAND_ABOVE'
ACTIVATION_LINK_SECRET: 'SECRET_KEY_FROM_COMMAND_ABOVE'
DB_SECRET: 'SECRET_KEY_FROM_COMMAND_ABOVE'
EMAIL_SECRET_SALT: 'SECRET_KEY_FROM_COMMAND_ABOVE'
PRIVATE_KEY: 'SECRET_KEY_FROM_COMMAND_ABOVE'
PUBLIC_KEY: 'SECRET_KEY_FROM_COMMAND_ABOVE'

# Switch DEBUG to false if you go into production
DEBUG: False

# Adjust this according to Django Documentation https://docs.djangoproject.com/en/2.2/ref/settings/
ALLOWED_HOSTS: ['*']

# Should be your domain without "www.". Will be the last part of the username
ALLOWED_DOMAINS: ['domain.de']

# If you want to disable registration, you can comment in the following line
# ALLOW_REGISTRATION: False

# If you want to disable the lost password functionality, you can comment in the following line
# ALLOW_LOST_PASSWORD: False

# If you want to enforce that the email address and username needs to match upon registration
# ENFORCE_MATCHING_USERNAME_AND_EMAIL: False

# If you want to restrict registration to some email addresses you can specify here a list of domains to filter
# REGISTRATION_EMAIL_FILTER: ['company1.com', 'company2.com']

# Should be the URL of the host under which the host is reachable
# If you open the url and append /info/ to it you should have a text similar to {"info":"{\"version\": \"....}
HOST_URL: 'https://psono.domain.de/server'

# The email used to send emails, e.g. for activation (Nice, but not necessary)
EMAIL_FROM: 'the-mail-for-for-example-useraccount-activations@test.com'
EMAIL_HOST: 'smtp.example.com'
EMAIL_HOST_USER: ''
EMAIL_HOST_PASSWORD : ''
EMAIL_PORT: 25
EMAIL_SUBJECT_PREFIX: ''
EMAIL_USE_TLS: False
EMAIL_USE_SSL: False
EMAIL_SSL_CERTFILE:
EMAIL_SSL_KEYFILE:
EMAIL_TIMEOUT: 10

# In case one wants to use mailgun, comment in below lines and provide the mailgun access key and server name
# EMAIL_BACKEND: 'anymail.backends.mailgun.EmailBackend'
# MAILGUN_ACCESS_KEY: ''
# MAILGUN_SERVER_NAME: ''

# In case you want to offer Yubikey support, create a pair of credentials here https://upgrade.yubico.com/getapikey/
# and update the following two lines before commenting them in
# YUBIKEY_CLIENT_ID: 'CLIENT_ID'
# YUBIKEY_SECRET_KEY: 'SECRET_KEY'

# If you have your own Yubico servers, you can specify here the urls as a list
# YUBICO_API_URLS: ['https://api.yubico.com/wsapi/2.0/verify']

# Cache enabled without belows Redis may lead to unexpected behaviour

# Cache with Redis
# By default you should use something different than database 0 or 1, e.g. 13 (default max is 16, can be configured in
# redis.conf) possible URLS are:
#    redis://[:password]@localhost:6379/0
#    rediss://[:password]@localhost:6379/0
#    unix://[:password]@/path/to/socket.sock?db=0
# CACHE_ENABLE: False
# CACHE_REDIS: False
# CACHE_REDIS_LOCATION: 'redis://127.0.0.1:6379/13'

# The server will automatically connect to the license server to get a license for 10 users.
# For paying customers we offer the opportunity to get an offline license code.
#
# LICENSE_CODE: |
#   0abcdefg...
#   1abcdefg...
#   2abcdefg...
#   3abcdefg...
#   4abcdefg...
#   5abcdefg...
#   6abcdefg...
#   7abcdefg...
#   8abcdefg...

# Enables the management API, required for the psono-admin-client / admin portal (Default is set to False)
MANAGEMENT_ENABLED: True

# Enables the fileserver API, required for the psono-fileserver
# FILESERVER_HANDLER_ENABLED: False

# Enables files for the client
# FILES_ENABLED: False

# Allows that users can search for partial usernames
# ALLOW_USER_SEARCH_BY_USERNAME_PARTIAL: True

# Allows that users can search for email addresses too
# ALLOW_USER_SEARCH_BY_EMAIL: True

# Disables central security reports
# DISABLE_CENTRAL_SECURITY_REPORTS: True

# Configures a system wide DUO connection for all clients
# DUO_INTEGRATION_KEY: ''
# DUO_SECRET_KEY: ''
# DUO_API_HOSTNAME: ''

# If you are using the DUO proxy, you can configure here the necessary HTTP proxy
# DUO_PROXY_HOST: 'the-ip-or-dns-name-goes-here'
# DUO_PROXY_PORT: 80
# DUO_PROXY_TYPE: 'CONNECT'
# If your proxy requires specific headers you can also configure these here
# DUO_PROXY_HEADERS: ''

# In case one wants to use iVALT, please add ivalt_secret_key. If you don't have then please write to ivat at 'support@ivalt.com'.
# IVALT_SECRET_KEY: ''

# Normally only one of the configured second factors needs to be solved. Setting this to True forces the client to solve all
# MULTIFACTOR_ENABLED: True

# Allows admins to limit the offered second factors in the client
# ALLOWED_SECOND_FACTORS: ['yubikey_otp', 'google_authenticator', 'duo', 'webauthn', 'ivalt']

# If you want to use LDAP, then you can configure it like this
#
# 		LDAP_URL: Any valid LDAP string, preferable with ldaps. usual urls are 'ldaps://example.com:636' or 'ldap://192.168.0.1:389'
#		LDAP_DOMAIN: Your LDAP domain, is added at the end of the username to form the full username
#		LDAP_BIND_DN: One User that can be used to search your LDAP
#		LDAP_BIND_PASS: The password of the user specified in LDAP_BIND_DN
#		LDAP_ATTR_GUID: The uuid attribute. e.g. on Windows 'objectGUID', but common are 'GUID' or 'entryUUID', default 'objectGUID'
#		LDAP_OBJECT_CLASS_USER: The objectClass value to filter user objects e.g. on Windows 'user', default 'user'
#		LDAP_OBJECT_CLASS_GROUP: The objectClass value to filter group objects e.g. on Windows 'group', default 'group'
#		LDAP_SEARCH_USER_DN: The "root" from which downwards we search for the users
#		LDAP_SEARCH_GROUP_DN: The "root" from which downwards we search for the groups
#		LDAP_ATTR_USERNAME: The username attribute to try to match against. e.g. on Windows 'sAMAccountName', default 'sAMAccountName'
#		LDAP_ATTR_EMAIL: The attribute of the user objects that holds the mail address e.g. on Windows 'mail', default 'mail'
#		LDAP_ATTR_GROUPS: The attribute of the user objects that holds the groups e.g. on Windows 'memberOf', default 'memberOf'
#		LDAP_REQUIRED_GROUP : The attribute to restrict access / usage. Only members of these groups can connect e.g. ['CN=groupname,OU=something,DC=example,DC=com'], default []
#		LDAP_CA_CERT_FILE: If you want to use ldaps and don't have a publicly trusted and signed certificate you can specify here the path to your ca certificate
#
#		LDAP_MEMBER_OF_OVERLAY: If your server has not this memberOf overlay, you can switch modes with this flag.
#                               Users will be mapped (based on their LDAP_MEMBER_ATTRIBUTE attribute) to groups (based on their LDAP_ATTR_MEMBERS attribute), default True
#		LDAP_MEMBER_ATTRIBUTE: The user attribute that will be used to map the group memberships, default 'uid'
#		LDAP_ATTR_MEMBERS: The group attribute that will be used to map the to the users LDAP_MEMBER_ATTRIBUTE attribute, default 'memberUid'
#
# To help you setup LDAP, we have created a small "testldap" command that should make things a lot easier. You can execute it like:
# docker run --rm \
#  -v /opt/docker/psono/settings.yaml:/root/.psono_server/settings.yaml \
#  -ti psono/psono-combo-enterprise:latest python3 psono/manage.py testldap username@something.com thePassWord
#
# For Windows AD it could look like this:
#
# LDAP : [
#     {
#         'LDAP_URL': 'ldaps://192.168.0.1:636',
#         'LDAP_DOMAIN': 'example.com',
#         'LDAP_BIND_DN': 'CN=LDAPPsono,OU=UsersTech,OU=example.com,DC=example,DC=com',
#         'LDAP_BIND_PASS': 'hopefully_not_123456',
#         'LDAP_SEARCH_USER_DN': 'OU=Users,OU=example.com,DC=example,DC=com',
#         'LDAP_SEARCH_GROUP_DN': 'OU=Groups,OU=example.com,DC=example,DC=com',
#     },
# ]
#
# If your server does not have the memberOf overlay, then you can also do something like this
#
# LDAP : [
#     {
#         'LDAP_URL': 'ldaps://192.168.0.1:636',
#         'LDAP_DOMAIN': 'example.com',
#         'LDAP_BIND_DN': 'CN=LDAPPsono,OU=UsersTech,OU=example.com,DC=example,DC=com',
#         'LDAP_BIND_PASS': 'hopefully_not_123456',
#         'LDAP_SEARCH_USER_DN': 'OU=Users,OU=example.com,DC=example,DC=com',
#         'LDAP_SEARCH_GROUP_DN': 'OU=Groups,OU=example.com,DC=example,DC=com',
#         'LDAP_OBJECT_CLASS_USER': 'posixAccount',
#         'LDAP_OBJECT_CLASS_GROUP': 'posixGroup',
#         'LDAP_ATTR_USERNAME': 'uid',
#         'LDAP_ATTR_GUID': 'entryUUID',
#         'LDAP_MEMBER_OF_OVERLAY': False,
#         'LDAP_MEMBER_ATTRIBUTE': 'uid',
#         'LDAP_ATTR_MEMBERS': 'memberUid',
#     },
# ]
#
# ATTENTION: API kays currently bypass LDAP authentication, that means API keys can still access secrets even if the
# user was disabled in LDAP. API keys can be disabled with COMPLIANCE_DISABLE_API_KEYS

# You also have to comment in the line below if you want to use LDAP (default: ['AUTHKEY'])
# For SAML authentication, you also have to add 'SAML' to the array.
# AUTHENTICATION_METHODS: ['AUTHKEY', 'LDAP']

# Enable Audit logging
# LOGGING_AUDIT: True

# To log to another destination you can specify this here, default '/var/log/psono'
# Never really necessary, as we will run the Psono server in a docker container and can mount /var/log/psono to any
# location on the underlying docker host.
# LOGGING_AUDIT_FOLDER: '/var/log/psono'

# If you prefer server time over utc, you can do that like below (default 'time_utc')
# LOGGING_AUDIT_TIME: 'time_server'

# If the server logs too much for you can either whitelist or blacklist events by their event code. (default: [])
# LOGGING_AUDIT_WHITELIST: []
# LOGGING_AUDIT_BLACKLIST: []

# If you are having Splunk and don't have a Splunk forwarder that can ship the logs, you can use Psono's native Splunk
# implementation to ship the logs for you. In order for that to work you need a Splunk HTTP EVent Collector to be
# configured as explained here https://dev.splunk.com/enterprise/docs/devtools/httpeventcollector/
# Afterwards configure the following variables:
# 
# SPLUNK_HOST The host, e.g. an ip or a domain
# SPLUNK_PORT The port, e.g. 8088 that you configured in the splunk http event collector
# SPLUNK_TOKEN The token of your splunk http event collector
# SPLUNK_INDEX The splunk index that you want the events to end up in By default 'main'
# SPLUNK_PROTOCOL 'http' or 'https' to indicate the protocol. By default 'https'
# SPLUNK_VERIFY True or False to indicate whether to verify certificates. By default True
# SPLUNK_SOURCETYPE The source type. By default 'psono:auditLog' (that one is compatible with the provided splunk addons)
#
# More infos can be found here https://github.com/zach-taylor/splunk_handler

# If you have an S3 bucket and want to ship your audit logs to S3, you can use Psono's native S3
# implementation to ship the logs for you:
# 
# S3_LOGGING_BUCKET The bucket name
# S3_LOGGING_ACCESS_KEY_ID The access key ID
# S3_LOGGING_SECRET_ACCESS_KEY The secret access key
#

# If you are having Logstash running and no way to ship logs with an external agent, you can use Psono's native Logstash
# implementation to ship the logs for you:
# 
# LOGSTASH_HANDLER Shipping logs either async (logstash_async.handler.AsynchronousLogstashHandler) or in sync (logstash_async.handler.SynchronousLogstashHandler). By default 'logstash_async.handler.SynchronousLogstashHandler'
# LOGSTASH_TRANSPORT The transport to use. TCP: logstash_async.transport.TcpTransport or UDP: logstash_async.transport.UdpTransport or Beats logstash_async.transport.BeatsTransport or HTTP logstash_async.transport.HttpTransport. Defaults to 'logstash_async.transport.TcpTransport'
# LOGSTASH_HOST The host, e.g. an ip or a domain
# LOGSTASH_PORT The port, e.g. 5959 that you configured the. By default 5959
# LOGSTASH_SSL_ENABLED Wether you want to use SSL or not. By default True
# LOGSTASH_SSL_VERIFY True or False whether to verify certificates. By default True
# LOGSTASH_CA_CERTS If you want a custom CA, you can specify here a path to the file with the certs
# LOGSTASH_CERFILE The path to the cert file
# LOGSTASH_KEYFILE The path to the key file
#
# More infos can be found here https://python-logstash-async.readthedocs.io/en/stable/index.html

# If you want to use SAML, then you can configure it like this as a dictionary.
#
# About the parameters:
#   idp->entityId: Thats the url to the metadata of your IDP
#   idp->singleLogoutService->url: Thats the url to the logout service of your IDP
#   idp->singleSignOnService->url: Thats the url to the single sign-on service of your IDP
#   idp->x509cert: Thats the certificate of your IDP
#   idp->groups_attribute: The attribute in the SAML response that holds your groups
#   idp->username_attribute: The attribute in the SAML response that holds the username. If you put here null, then it will use the NameID
#   idp->email_attribute: The attribute in the SAML response that holds the email address.
#   idp->username_domain: The domain that is appended to the provided username, if the provided username is not already in email format.
#   idp->required_group: A list of group names (casesensitive) in order to restrict who can use SAML login with this installation. Leave empty for no restriction.
#   idp->is_adfs: If you are using ADFS.
#   idp->honor_multifactors: Multifactor authentication can be bypassed with this flag for all SAML users (e.g. when you already enforce multifactor on the SAML provider).
#   idp->max_session_lifetime: The time in seconds that a session created throught SAML will live
#
#   sp->NameIDFormat: The normal nameformat parameter. (should only be set to transient if you have set a username attribute with username_attribute)
#   sp->attributeConsumingService: Only necessary if the IDP needs to be told to send some specific attributes
#   sp->x509cert: The X.509 cert
#   sp->privateKey: The corresponding private key of the X.509 cert
#
# There are a couple of more options next to those required ones below.
# More information can be found here https://github.com/onelogin/python3-saml
#
# A self-signed certificate can be generated with:
# openssl req -new -newkey rsa:2048 -x509 -days 3650 -nodes -sha256 -out sp_x509cert.crt -keyout sp_private_key.key
#
# To help you setup SAML, we have created a small "testsaml" command that should make things easier. You can execute it like:
# docker run --rm \
#  -v /opt/docker/psono/settings.yaml:/root/.psono_server/settings.yaml \
#  -ti psono/psono-combo-enterprise:latest python3 psono/manage.py testsaml
#
# The number 1 in line 2 is the provider id. Users are matched by the constructed username.
#
# SAML_CONFIGURATIONS:
#     1:
#         idp:
#             entityId: "https://idp.exampple.com/metadata.php"
#             singleLogoutService:
#                 binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
#                 url: "https://idp.exampple.com/SingleLogoutService.php"
#             singleSignOnService:
#                 binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
#                 url: "https://idp.exampple.com/SingleSignOnService.php"
#             x509cert: "ABC...=="
#             groups_attribute: "groups"
#             username_attribute: 'username'
#             email_attribute: 'email'
#             username_domain: 'example.com'
#             required_group: []
#             is_adfs: false
#             honor_multifactors: true
#             max_session_lifetime: 86400
#         sp:
#             NameIDFormat: "urn:oasis:names:tc:SAML:2.0:nameid-format:persistent"
#             assertionConsumerService:
#                 binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-POST"
#             attributeConsumingService:
#                 serviceName: "Psono"
#                 serviceDescription: "Psono password manager"
#                 requestedAttributes:
#                     -
#                         attributeValue: []
#                         friendlyName: ""
#                         isRequired: false
#                         name: "attribute-that-has-to-be-requested-explicitely"
#                         nameFormat: ""
#             privateKey: "ABC...=="
#             singleLogoutService:
#                 binding: "urn:oasis:names:tc:SAML:2.0:bindings:HTTP-Redirect"
#             x509cert: "ABC...=="
#             autoprovision_psono_folder: false
#             autoprovision_psono_group: false
#         strict: true
#
# You need a couple of urls to configure the IDP correctly. If the server is accessible under https://example.com/server
# (e.g. https://example.com/server/healthcheck/ shows some json output) and the provider id is 1 as in the example
# above the folling urls are valid:
#
# for metadata :                   https://example.com/server/saml/1/metadata/
# for assertion consumer service : https://example.com/server/saml/1/acs/
# for single logout service :      https://example.com/server/saml/1/sls/
#
#
# ATTENTION: API kays currently bypass SAML authentication, that means API keys can still access secrets even if the
# user was disabled in SAML. API keys can be disabled with COMPLIANCE_DISABLE_API_KEYS

# If you want to use OIDC, then you can configure it like this as a dictionary.
# OIDC_CONFIGURATIONS:
#     1:
#         OIDC_RP_SIGN_ALGO: 'RS256'
#         OIDC_RP_CLIENT_ID: 'whatever client id was provided'
#         OIDC_RP_CLIENT_SECRET: 'whatever secret was provided'
#         OIDC_OP_JWKS_ENDPOINT: 'https://example.com/jwks'
#         OIDC_OP_AUTHORIZATION_ENDPOINT: 'https://example.com/authorize'
#         OIDC_OP_TOKEN_ENDPOINT: 'https://example.com/token'
#         OIDC_OP_USER_ENDPOINT: 'https://example.com/userinfo'
#
# Standard parameters explained:
# OIDC_RP_SIGN_ALGO defaults to HS256 and needs to match the algo of your IDP
# OIDC_RP_CLIENT_ID the client id that is provided by your IDP
# OIDC_RP_CLIENT_SECRET the secret that is provided by your IDP
# OIDC_OP_JWKS_ENDPOINT The JWKS endpoint of your IDP
# OIDC_OP_AUTHORIZATION_ENDPOINT The authorization endpoint of your IDP
# OIDC_OP_TOKEN_ENDPOINT The token endpoint of your IDP
# 
# other parameters are:
# OIDC_VERIFY_JWT defaults to true, Controls whether Psono verifies the signature of the JWT tokens
# OIDC_USE_NONCE defaults to true, Controls whether Psono uses nonce verification
# OIDC_VERIFY_SSL defaults to true, Controls whether Psono verifies the SSL certificate of the IDP responses
# OIDC_TIMEOUT defaults to 10, Defines a timeout for all requests in seconds to the IDP (fetch JWS, retrieve JWT tokens, userinfo endpoint))
# OIDC_PROXY defaults to None, Defines a proxy for all requests to the IDP (fetch JWS, retrieve JWT tokens, Userinfo Endpoint). More infos can be found here https://requests.readthedocs.io/en/master/user/advanced/#proxies
# OIDC_RP_SCOPES defaults to 'openid email', The OpenID Connect scopes to request during login.
# OIDC_AUTH_REQUEST_EXTRA_PARAMS defaults to {}, Additional parameters to include in the initial authorization request.
# OIDC_RP_IDP_SIGN_KEY defaults to None, Sets the key the IDP uses to sign ID tokens in the case of an RSA sign algorithm. Should be the signing key in PEM or DER format.
# OIDC_ALLOW_UNSECURED_JWT defaults to False, Controls whether the Psono is going to allow unsecured JWT tokens (tokens with header {"alg":"none"}). This needs to be set to True if the IDP is returning unsecured JWT tokens and you want to accept them. See also https://tools.ietf.org/html/rfc7519#section-6
# OIDC_TOKEN_USE_BASIC_AUTH defaults to False, Use HTTP Basic Authentication instead of sending the client secret in token request POST body.

# Your Postgres Database credentials
# ATTENTION: If executed in a docker container, then "localhost" will resolve to the docker container, so
# "localhost" will not work as host. Use the public IP or DNS record of the server.
DATABASES:
    default:
        'ENGINE': 'django.db.backends.postgresql_psycopg2'
        'NAME': 'psono'
        'USER': 'psono'
        'PASSWORD': 'S3cr3t'
        'HOST': 'postgres'
        'PORT': '5432'
# for master / slave replication setup comment in the following (all reads will be redirected to the slave
#    slave:
#        'ENGINE': 'django.db.backends.postgresql_psycopg2'
#        'NAME': 'YourPostgresDatabase'
#        'USER': 'YourPostgresUser'
#        'PASSWORD': 'YourPostgresPassword'
#        'HOST': 'YourPostgresHost'
#        'PORT': 'YourPostgresPort'

# The path to the template folder can be "shadowed" if required later
TEMPLATES: [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': ['/root/psono/templates'],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.debug',
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]
```

### Erstellen der Client `config.json` in `/srv/psono/config/config.json`
```json
{
  "backend_servers": [{
    "title": "PSONO",
    "url": "https://psono.domain.de/server"
  }],
  "base_url": "https://psono.domain.de/",
  "allow_custom_server": true,
  "allow_registration": true,
  "allow_lost_password": true,
  "disable_download_bar": false,
  "remember_me_default": false,
  "trust_device_default": false,
  "authentication_methods": ["AUTHKEY", "LDAP"],
  "saml_provider": []
}
```
Einzelne Attribute können gemäß persönlichen Präferenzen angepasst werden. Ansonsten kann die config nach Änderung der 
Domains so ohne Probleme verwendet werden und jederzeit auch noch später angepasst werden.

### Cronjob erstellen
1. Öffne den root Crontab mit `sudo crontab -e`
2. Füge am Ende der Datei folgende Zeile ein `30 2 * * * docker exec psono-psono-combo-1 python3 ./psono/manage.py cleartoken`


### User erstellen
```shell
docker compose exec python3 ./psono/manage.py createuser \
                username@example.com \
                myPassword \
                email@something.com
```

Jetzt kann der User sich unter https://psono.domain.de/ einloggen.


### User zum Admin erklären
```shell
docker compose exec python3 ./psono/manage.py promoteuser username@example.com superuser
```

Der Admin Login (mit einem Dashboard, Userverwaltung, etc.) befindet sich unter https://psono.domain.de/portal/


Weiter Informationen: [Offizelle Dokumentation](https://doc.psono.com/admin/overview/summary.html)
