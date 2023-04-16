# Admin Guide: Ansible

## Structure
Even though the structure is self explaining here are some comments:
```sh
ansible/
├── hosts.yaml                                 # contains basic inventory
│                                              #  - sites with targets fully qualified domain names
│                                              #  - default settings for variables (e.g. all roles to install = false)
├── .operator.yaml                             # operator specific secrets (e. g. cloudflare dns management token)
├── group_vars                                 # contains group specific encrypted vaults
│   │                                          #  - all: internal cloudflare dns token
│   └── all
├── host_vars                                  # contains host specific variables
│   │                                          #  - roles to install
│   │                                          #  - nginx vhosts
│   │                                          #  - users
│   └── example.admin-guide.com.yaml
├── roles
│   ├── ansible-role-docker                    # from github.com/geerlingguy/ansible-role-docker
│   └── ansible-role-adminguide_nginx          # setup nginx
├── tasks                                      # contains tasks to be run within the playbook
└── templates
```

## Usage Instuructions

### Setup Ansible
```shell
pip3 install ansible ansible-lint
ansible-galaxy collection install community.general

git clone https://github.com/felbinger/adminguide
cd adminguide
git submodule update
cd ansible
```

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
ansible-playbook servers.yml -l example.admin-guide.com

# only play a specific part from the servers playbook using tags (use --list-tasks to see which tags are defined)
ansible-playbook servers.yml -l example.admin-guide.com --tags nginx

# lint after you changed something
ansible-lint
```

