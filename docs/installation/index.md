## Base
First we update the package lists, kernel and other distribution specific stuff.
<br>
Then we install some tools that are needed for this guide.
```bash
apt-get update
apt-get -y dist-upgrade
apt-get -y install apt sudo curl nano
```

## Change Hostname [optional]
In most cases, your hosting provider gave your machine an ugly hostname.
Just change it in the files `/etc/hostname` and `/etc/hosts` to your new one according to the following example:
```bash
# /etc/hostname
<hostname>
```
```bash
# /etc/hosts

127.0.0.1	      localhost
127.0.1.1	      <fqdn.domain.tld> <hostname>  # <--
<ipv4>            <fqdn.domain.tld> <hostname>  # <--

# The following lines are desirable for IPv6 capable hosts
::1               localhost ip6-localhost ip6-loopback
ff02::1           ip6-allnodes
ff02::2           ip6-allrouters
```

!!! warning ""
    IPv6-FQDN is missing, although I never set up a server using ipv6.

In this case I decided to use the hostname `server` and assign the fully qualified domain name `fqdn.domain.tld` to it.
To apply the changes, you need to restart the server.

## The Admin Group
On every server that is managed by me, there exists an `admin` group that has access to almost all service configuration files.
This group is used to easily manage many administrators on one server.
```bash
groupadd -g 997 admin
mkdir /home/admin
chown -R root:admin /home/admin
chmod -R 775 /home/admin
```

## Create Users
You should create at least one user, and use it instead of the `root` user.
Let's create a new user called `user` and add him to the groups `sudo` and `admin`.

=== "default"
    ```bash
    adduser user
    usermod -aG sudo,admin user
    ```
=== "any"
    ```bash
    adduser <user>
    usermod -aG sudo,admin <user>
    ```

!!! note ""
    You can repeat this part for any other user who needs administrative access.

## Setup SSH Keys
SSH keys are a fundamental for secure connection to your server.

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
    # a list off all types, witch are supportet by your system: (second line)
    ssh-keygen -h

    ssh-keygen -t <type>
    ```

### Setup SSH Keys on the server
There are multiple options to add your public keys to the file `~/.ssh/authorized_keys`:

=== "Client Side"
    One option is to use `ssh-copy-id` on the client machine (and authenticate yourself with for example a password),
    and the ssh client automatically copy the keys there.

    === "default key"
        ```bash
        ssh-copy-id <user>@<ip>
        ```
    === "specific key"
        ```bash
        ssh-copy-id -i <keyfile> <user>@<ip>
        ```
    
    !!! note ""
        `ssh-copy-id` uses the description of your public key.


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

## Securing the SSH Server
After we successfully logged in using one of our user accounts, we can reconfigure ssh.
We set the following values:
```bash
# /etc/ssh/sshd_config

# disallow authentication with passwords
PasswordAuthentication no

# disallow login via root
PermitRootLogin no

# maximum number of authentication attempts
MaxAuthTries 3

# maximum number of sessions of one user that can be logged in at the same time
MaxSessions 5
```

!!! info ""
    Don't forget to restart your SSH Server:
    ```bash
    sudo systemctl restart ssh
    ```

!!! warning ""
    Make sure you can log in using your SSH private key, otherwise you are not able to login again after the next step!
