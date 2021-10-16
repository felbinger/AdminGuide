# Wireguard

We will use an instation script, because we don't want to use the full possibilities of wireguard. The script is created for the server only a simple vpn and runs on the distributions listed below.

## Supported distributions

- ✅ Ubuntu >= 16.04
- ✅ Debian >= 10
- ✅ Fedora
- ✅ CentOS
- ✅ Arch Linux

# Features
- ✅ script supports both IPv4 and IPv6
- ✅ script supports multi users
- ✅ create qr to scan with phone

# Installion


Download and execute the script. Answer the questions asked by the script and it will take care of the rest.

```bash

curl -O https://raw.githubusercontent.com/angristan/wireguard-install/master/wireguard-install.sh
chmod +x wireguard-install.sh
./wireguard-install.sh
```

# After installion

Here you can manage the users or uninstall WireGuard. Choose your option and the script will do the job.
### Choice possibilities

- Add a new user
- Revoke existing user
- Uninstall WireGuard
