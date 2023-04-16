## TODO REALLY IMPORTENT!!!
* storagebox_user
* storagebox_subdomain


# Secure Shell Networks: Ansible 2.0

This is the ansible repository which is responsable for servers, the ansible repository for vyos routers is in the [ansible-vyos](https://gitea.secshell.pve3.secshell.net/secshell.net/ansible-vyos) repository.

## Structure
Even though the structure is self explaining here are some comments:
```sh
ansible/
├── hosts.yaml                                 # <-- contains basic inventory
│                                              #     - sites with targets fully qualified domain names
│                                              #     - default settings for variables (e.g. all roles to install = false)
├── .operator.yaml                             # <-- operator specific secrets (e. g. cloudflare dns management token)
├── group_vars                                 # <-- contains group specific encrypted vaults
│   │                                          #     - site: oidc-auth configuration
│   │                                          #     - all: internal cloudflare dns token
│   │                                          #     - all: rsync exporter password
│   ├── all
│   ├── parents
│   ├── pve0
│   ├── pve1
│   └── pve3
├── host_vars                                  # <-- contains host specific variables
│   │                                          #     - roles to install
│   │                                          #     - nginx vhosts
│   │                                          #     - users
│   ├── backup.pve3.secshell.net.yaml
│   ├── general.pve1.secshell.net.yaml
│   ├── general.pve3.secshell.net.yaml
│   ├── log.pve3.secshell.net.yaml
│   ├── monitoring.pve1.secshell.net.yaml
│   ├── monitoring.pve3.secshell.net.yaml
│   ├── secshell.pve3.secshell.net.yaml
│   └── woodpecker.pve0.secshell.net.yaml
├── roles
│   ├── ansible-role-docker                    # from github.com/geerlingguy/ansible-role-docker
│   ├── ansible-role-mailcow                   # from github.com/mailcow/mailcow-ansiblerole
│   ├── ansible-role-secshell_backup           # [WIP] setup borg, borg exporting, keycloak and database backup
│   ├── ansible-role-secshell_logging          # role to configure syslog logging
│   ├── ansible-role-secshell_monitoring       # [WIP] setup cadvisor, node_exporter, docker_exporter on the host
│   ├── ansible-role-secshell_nginx            # [WIP] setup nginx automaticly
│   ├── ansible-role-secshell_pam_oidc         # setup ssh oidc auth using keycloak
│   └── ansible-role-secshell_users            # create admin directory structure and users
└── templates
```

## Usage Instuructions

### Setup Ansible
```shell
pip3 install ansible ansible-lint
ansible-galaxy collection install community.general

git clone https://gitea.secshell.pve3.secshell.net/secshell.net/ansible.git
git submodule update
```

### Work with Ansible
First you should request the required keys (to decrypt the 
ansible vaults) for the site, you're going to administrate.
@nicof2000 will send these, on request, to you if you are authorized for the site.
Also you might need to create the `.operator.yaml` file 
with the cloudflare secrets for dns management and to create 
origin server certificates, for the nginx role. 
Checkout the next chapter for this. 
If you haven't yet received access to the domains of 
your site, contact @nicof2000 again.

### Create `.operator.yaml`
```yaml
---
operator_cf_ca_key: ""
operator_cf_dns_token: ""
```

![API token settings for the `operator_cf_ca_key`](./.img/cloudflare_operator_dns_token.png)
![How to get `operator_cf_dns_token`](./.img/cloudflare_operator_ca_key.png)

### Ansible Usage

```shell
# check reachability of hotsts
ansible all -m ping

# check inventory (to validate that you didn't forget to add any variables to a host)
ansible-inventory --vars --graph

# run playbook on single hosts (-l|--limit can be used to run it only on one host)
ansible-playbook servers.yml -l general.pve3.secshell.net

# only play a specific part from the servers playbook using tags (use --list-tasks to see which tags are defined)
ansible-playbook servers.yml -l general.pve3.secshell.net --tags pam_oidc

# lint after you changed something
ansible-lint
```

