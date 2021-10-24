# Home

This Admin Guide describes how I setup my servers using docker.

## Installation

I created a script which can be executed to setup the server.  
I suggest you to get used to my structure (e.g. the stack logic), otherwise you might run into problems later on.  
If you never used this guide, you should [perform the installation manually](./installation/) to understand the structure.

<details>
  <summary>Post Installation Script</summary>

<br>
You can basicly skip most of the installation section, but there are some exceptions.

<ul>
  <li>
  First you should create all user accounts, and ensure that everyone is able to authenticate using public key authentication.
  </li>
  <li>
  You can add the users in the configuration section of the `postinstall.sh` to give them the groups, aliases, ... After you are sure that you can connect to the server you should secure your ssh server (e.g. disallow authentication using passwords, root login, ...).  
  </li>

  <li>
  If you want to change your hostname to something cooler than the name your hoster assigned you (this is not required, I do it to improve the identification process of the server, that I'm connected to).  
  </li>

  <li>
  You also need to setup your dns records, consider to change the name servers to cloudflare if you have trouble with the dns challenge for wildcard certificate later on.
  </li>
</ul>

```
curl -fsSL https://raw.githubusercontent.com/felbinger/AdminGuide/master/postinstall.sh | sudo bash
```

Checkout the <a href="/AdminGuide/installation/postinstall/">demo of the postinstall script</a>.

</details>

## Create your Services

After you successfully installed your system, you can add the services you need.  
Before you add a new service think which stack fits best. It might be useful to create a new stack.

You can find a lot of services (e.g. Databases, Gameserver, Apps for Communication, Apps for File Storage, ...) in the navigation bar on the left side of the page.
Simply add them to your `docker-compose.yml` and modify the required attributes (e.g. passwords, domain name, routing configuration, ...).

### Environment Variables
I don't put environment variables in the `docker-compose.yml`, instead I create a `.<service_name>.env` file, in which all environment variables are defined.
Afterwards I add this environment file using `env_file: .<service_name>.env` to the service, defined in the `docker-compose.yml`.
The main reason for that is, to prevent password leaks: e.g. screensharing, or if you send someone your service definition

## Tools

### [ctop](https://ctop.sh/)

Simple commandline monitoring tool for docker containers:

```bash
sudo wget https://github.com/bcicen/ctop/releases/download/0.7.6/ctop-0.7.6-linux-amd64 \
  -O /usr/local/bin/ctop
sudo chmod +x /usr/local/bin/ctop
```
