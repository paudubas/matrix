# 6 — Ansible: matrix-docker-ansible-deploy

A full Matrix stack (Synapse by default, Postgres, Traefik with automatic Let's Encrypt HTTPS, Element Web) installed on one Linux server by the community playbook [spantaleev/matrix-docker-ansible-deploy](https://github.com/spantaleev/matrix-docker-ansible-deploy). Unlike scenarios 1–5 it gives you real HTTPS and federation. It needs a domain, or a free sslip.io hostname when using the Hetzner VM from `ansible.tf`.

**Status: prepared, not run.** The Terraform for the server is written and validated but not applied. A new server costs money (about €5.49/month before VAT); get approval before applying.

Sources of truth: the playbook's [prerequisites](https://github.com/spantaleev/matrix-docker-ansible-deploy/blob/master/docs/prerequisites.md) and [quick start](https://github.com/spantaleev/matrix-docker-ansible-deploy/blob/master/docs/quick-start.md). Follow them if they differ from this page.

## Install first (laptop)

```bash
brew install ansible just git pwgen     # macOS
ansible --version && just --version
ssh-keygen -t ed25519                   # if you have no SSH key yet
```

Linux/Windows: see the playbook's [Ansible guide](https://github.com/spantaleev/matrix-docker-ansible-deploy/blob/master/docs/ansible.md) (Windows: use WSL).

## Option A: server on Hetzner via Terraform, no domain needed (prepared)

`../04-hetzner-terraform/ansible.tf` defines a third `cx23` Ubuntu 24.04 VM (about €5.49/month before VAT, same as the others) with your SSH key, and a firewall: SSH only from `allowed_client_ips`, ports 80, 443 and 8448 open to everyone (needed by Let's Encrypt and federation). It uses a free [sslip.io](https://sslip.io) hostname, so `matrix.<ip-with-dashes>.sslip.io` and `element.<ip-with-dashes>.sslip.io` resolve to the server and Let's Encrypt can issue certificates without you owning a domain.

1. Create an SSH key if you have none: `ssh-keygen -t ed25519` (or set `ansible_ssh_public_key_path` in `terraform.tfvars`).
2. With `HCLOUD_TOKEN` exported in your own terminal, review and apply (this creates a billed server; check the plan):

   ```bash
   terraform -chdir=04-hetzner-terraform plan
   terraform -chdir=04-hetzner-terraform apply
   terraform -chdir=04-hetzner-terraform output ansible_server_ipv4
   terraform -chdir=04-hetzner-terraform output ansible_base_domain
   ```
3. Use the printed IP and base domain as `<server-ip>` and `example.com` in **Run** below, e.g. `just add-inventory-host 49-0-2-1.sslip.io 49.0.2.1`.

Caveats: sslip.io is a shared free service and Let's Encrypt rate limits apply to it, so a failed issuance may need a retry later. The domain changes if the server is recreated, which changes every Matrix ID. `terraform destroy` removes all three VMs of scenarios 4, 5 and 6; use `-target` to remove only this one.

## Option B: your own server and domain

1. **A server**: x86, Debian 12+ or Ubuntu 22.04+ (newer is better), 2 GB+ RAM, public IPv4, `root` or sudo SSH access with your public key, and `python3` and `sudo` installed. Ports 80, 443 and 8448 must be reachable: Let's Encrypt needs 80/443 and federation uses 8448.
2. **A domain** (here `example.com`) with DNS records pointing to the server IP:

   | Name | Type | Value |
   |---|---|---|
   | `matrix.example.com` | A | server IP |
   | `element.example.com` | A or CNAME | `matrix.example.com` |
   | `example.com` | — | must serve `/.well-known/matrix/*` over HTTPS, or let the Matrix server serve it; see the playbook's [base domain docs](https://github.com/spantaleev/matrix-docker-ansible-deploy/blob/master/docs/configuring-playbook-base-domain-serving.md) |

The domain becomes part of every Matrix ID (`@you:example.com`) and can't be changed later without reinstalling.

## Run

The clone and its inventory (which holds generated secrets) are git-ignored in this repo.

```bash
cd 06-ansible-playbook
git clone https://github.com/spantaleev/matrix-docker-ansible-deploy.git
cd matrix-docker-ansible-deploy

# Creates inventory/hosts and inventory/host_vars/matrix.example.com/vars.yml with generated secrets
just add-inventory-host example.com <server-ip>
```

Edit `inventory/host_vars/matrix.example.com/vars.yml` per the quick start (at minimum your base domain and, for Let's Encrypt, a contact email). Edit `inventory/hosts` if your SSH user isn't `root` (`ansible_user=...`, `ansible_become=true`).

```bash
just roles                                                      # download Ansible roles
ansible-playbook -i inventory/hosts setup.yml --tags=install-all,ensure-matrix-users-created,start
```

Then create the admin. The helper prompts for the password (never stored) and runs the playbook's `register-user` step:

```bash
./register-user.sh              # from 06-ansible-playbook/; creates "admin" (or the VS Code task "Create Ansible Matrix admin")
./register-user.sh alice user   # a normal user
```

Sign in at `https://element.example.com` as `admin` (Matrix ID `@admin:example.com`; with the Hetzner option, `https://element.<ip-with-dashes>.sslip.io`).

Check the server: `curl https://matrix.example.com/_matrix/client/versions`. For federation, use the Matrix federation tester once DNS and HTTPS are right.

## Operate

```bash
just update                                                              # pull playbook + roles
ansible-playbook -i inventory/hosts setup.yml --tags=install-all,start   # re-apply config / upgrade
ansible-playbook -i inventory/hosts setup.yml --tags=stop                # stop services
```

Back up `inventory/` (secrets) and the server's `/matrix` directory before upgrades. Remove everything with the playbook's uninstall steps (see its docs) and delete the server in your provider's console to stop charges.
