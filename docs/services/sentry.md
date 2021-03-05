### Check out the [Official Guide](https://develop.sentry.dev/self-hosted/)

Setting up Sentry
=================

I highly recommend creating an own Stack for Sentry. Pull the latest release of https://github.com/getsentry/onpremise
and execute the `install.sh` to create the basic configuration and the initial user. Afterwards we have to modify the provided
Compose-File to work with Traefik.

I also removed the environment variables and mapped the volumes to the Host-Filesystem, but that is not necessary.
The relevant section for us to edit is the `nginx` Service, where we add those labels:

```
labels:
  - "traefik.enable=true"
  - "traefik.http.services.srv_sentry.loadbalancer.server.port=80"
  - "traefik.http.routers.r_sentry.rule=Host(`sentry.example.com`)"
  - "traefik.http.routers.r_sentry.entrypoints=websecure"
```

**Keep in mind that this Container and Traefik have to be in the same Docker network to communicate.**

We can leave the rest of the Compose-File as it is. Now we can run `docker-compose up -d` to start Sentry; 
if everything is alright sentry should now be reachable under the given domain.

Configuring SSO with Keycloak
=============================

We can use Keycloak to log into Sentry via the SAML2 Protocol. At first, we have to configure Keycloak.

Create a new Client. **The Client ID must be `https://sentry.example.com/saml/metadata/sentry/`.** The Client
Protocol is `saml`.

Now edit the Client. Leave all Settings as they are, except for the following:


Setting | Value
--------|--------
Client Signature required | OFF
Valid redirect URIs | `https://sentry.example.com/*`
Base URL | `https://sentry.example.com`


"Fine Grain SAML Endpoint Configuration":

Setting | Value
--------|------
Assertion Consumer Service POST Binding URL | `https://sentry.example.com/saml/acs/sentry/`
Logout Service Redirect Binding URL | `https://sentry.example.com/saml/sls/sentry/`

<br /> <br />
Save this. Now go to the "Mappers"-Tab. Create a new Mapper:

Setting | Value
--------|------
Name | username
Mapper Type | user property
Property | username
Friendly Name | Username
SAML Attribute Name | user.username
SAML Attribute NameFormat | basic


Save this. Create another Mapper:

Setting | Value
--------|-------
Name | email
Mapper Type | user property
Property | email
Friendly Name | User Email
SAML Attribute Name | user.email
SAML Attribute NameFormat | basic


Also hit save on this one. Now we are almost done with the Keycloak Config. There is just one
more Setting we need to change, and that is the following:

Go to `Client Scopes -> role_list -> Mappers -> role list` and set "Single Role Attribute" to ON. Save.
Now we have finished the Keycloak Configuration.

Let's get to Sentry. Login with the initial User you created earlier. Now go to 
`Settings -> Auth -> SAML2 Authentication -> Configure`. A new Tab will open.

Use the Tab `IdP Data` and enter the following Information:

```
Entity ID: https://keycloak.example.com/auth/realms/YOURREALM

Single Sign On URL: https://keycloak.example.com/auth/realms/YOURREALM/protocol/saml

Single Log Out URL: https://keycloak.example.com/auth/realms/YOURREALM/protocol/saml

x509 public certificate: -> Next step
```

To get the x509 public certificate you have to open the Keycloak Admin once again.
In the `Realm Settings`, click on `SAML 2.0 Identity Provider Metadata`. Now copy and paste
the shown public certificate to Sentry. Now continue.

If everything worked, you will be asked to do some Attribute Mapping. Just enter the following:

```
IdP User ID: user.username
User Email: user.email
```

You can leave the name fields empty and continue. You should be redirected to your Keycloak to login.
If everything worked well you will be redirected back to Sentry afterwards.

You can now login to Sentry via your Keycloak. For further Guidance you can use the
[official Documentation](https://docs.sentry.io/product/accounts/sso/saml2/).

**Important: Do not forget to change the Settings in Keycloak after you rename your Sentry Organization!**

e. g. if you rename your Organization from "Sentry" to "Foobar", you would have to modify the
Links in Keycloak properly.

The Client ID would now be `https://sentry.example.com/saml/metadata/foobar`, the ACS would be
`https://sentry.example.com/saml/acs/foobar` and the SLS would be `https://sentry.example.com/saml/sls/foobar`.