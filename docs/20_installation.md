# Installation

Even though I never wanted this, here is the basic setup of my servers:

## Base
First we update the package lists, kernel and other distribution specific stuff.
<br>
Then we install some tools that are needed for this guide.
```shell
apt-get update
apt-get -y dist-upgrade
apt-get -y install apt sudo curl nano
```

## Change Hostname [optional]
In most cases, your hosting provider gave your machine an ugly hostname.
Just change it in the files `/etc/hostname` and `/etc/hosts` to your new one according to the following example:
```shell
# /etc/hostname
<hostname>
```
```shell
# /etc/hosts

127.0.0.1	      localhost
<ipv4>            <fqdn.domain.tld> <hostname>  # <--

# The following lines are desirable for IPv6 capable hosts
::1               localhost ip6-localhost ip6-loopback
ff02::1           ip6-allnodes
ff02::2           ip6-allrouters
<ipv6>            <fqdn.domain.tld> <hostname>  # <--
```

To apply the changes, you need to restart the server.

## The Admin Group
On every server that is managed by me, there exists an `admin` group that has access to almost all service configuration files.
This group is used to easily manage multiple administrators on one server.
```shell
groupadd -g 997 admin
mkdir /home/admin
chown -R root:admin /home/admin
chmod -R 775 /home/admin
```

## Create Users
You should create at least one user, and use it instead of the `root` user.
Let's create a new user called `nicof2000` and add him to the groups `sudo` and `admin`.

```shell
adduser nicof2000
usermod -aG sudo,admin nicof2000
```

## Setup SSH Keys
SSH keys are a fundamental for secure connections to your server.

### Create SSH Keys
If you don't already have an SSH Key it is recommended to create one:

=== "rsa"
    ```bash
    ssh-keygen -t rsa
    ```
=== "dsa"
    ```bash
    ssh-keygen -t dsa
    ```
=== "ecdsa"
    ```bash
    ssh-keygen -t ecdsa
    ```
=== "ed25519"
    ```bash
    ssh-keygen -t ed25519
    ```
=== "other"
    ```bash
    # a list off all types, which are supported by your system: (second line)
    ssh-keygen -h

    ssh-keygen -t <type>
    ```

### Setup SSH Keys on the server
There are multiple options to add your public keys to the file `~/.ssh/authorized_keys`:

=== "Client Side"
    One option is to use `ssh-copy-id` on the client machine (and authenticate yourself with for example a password),
    and the ssh client automatically copies the keys there.

    === "default key"
        ```bash
        ssh-copy-id <user>@<ip>
        ```
    === "specific key"
        ```bash
        ssh-copy-id -i <keyfile> <user>@<ip>
        ```

=== "Server Side"
    Another options is to append your public key manually to the `~/.ssh/authorized_keys` file in the following format `ssh-<type> <public_key> [description]`:

    === "rsa"
        ```bash
        echo "ssh-rsa <key> [description]" >> ~/.ssh/authorized_keys
        ```
    === "dsa"
        ```bash
        echo "ssh-dsa <key> [description]" >> ~/.ssh/authorized_keys
        ```
    === "ecdsa"
        ```bash
        echo "ssh-ecdsa <key> [description]" >> ~/.ssh/authorized_keys
        ```
    === "ed25519"
        ```bash
        echo "ssh-ed25519 <key> [description]" >> ~/.ssh/authorized_keys
        ```
    === "other"
        ```bash
        echo "ssh-<type> <key> [description]" >> ~/.ssh/authorized_keys
        ```

    !!! warning ""
        Note that you must be logged in as the user for whom the SSH key will be added.

## Docker
Docker itself already provides a very good script:

```shell
curl -fsSL https://get.docker.com | sudo bash
```

Instead of typing `sudo docker compose up -d` all the time you can use this alias and type `dc up -d`:

```shell
echo 'alias dc="sudo docker compose "' >> ~/.bashrc
```

## DNS Setup
As I already mentioned in the introduction, you need to use the Cloudflare proxy for this guide.
This means, you need to use the Cloudflare name servers, check out 
[support.cloudflare.com](https://support.cloudflare.com/hc/en-us/articles/205195708-Changing-your-domain-nameservers-to-Cloudflare) 
for a guide on how to do this.
