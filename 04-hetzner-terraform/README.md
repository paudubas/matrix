# 4 — Terraform: Tuwunel on Hetzner

`main.tf` defines one `cx23` Ubuntu VM (`nbg1`), one IPv4, a firewall and Tuwunel in Docker (cloud-init). Server `http://49.13.150.188:8008`, about €5.49/month before VAT (cap €6).

`native.tf` in this folder defines the second VM used by [scenario 5](../05-bare-metal/README.md); both share one state, so keep them together.

It is plain HTTP, restricted to the client IP in `allowed_client_ips` (`terraform.tfvars`); update it if your public IP changes. Not configured for federation. The server name is the VM's IP, so recreating the VM changes Matrix IDs. Use only disposable accounts and unique passwords.

## Install first

1. **Terraform** ≥ 1.5:

   ```bash
   brew tap hashicorp/tap && brew install hashicorp/tap/terraform   # macOS
   terraform version
   ```

   Linux/Windows: <https://developer.hashicorp.com/terraform/install>.
2. **A Hetzner Cloud account** with a project (<https://console.hetzner.cloud>). A payment method is required and servers are billed.
3. **An API token** with Read & Write: project → Security → API tokens. Export it only in your own terminal, never paste it in chat or commit it:

   ```bash
   export HCLOUD_TOKEN='...'
   ```
4. Your public IPv4 for the firewall (e.g. `curl -4 ifconfig.me`). Put it in a git-ignored `terraform.tfvars`: `allowed_client_ips = ["<your-ip>/32"]`.

No SSH key or other local tools are needed; the VMs configure themselves with cloud-init.

Terraform state contains the registration tokens: keep it private (git-ignored). `HCLOUD_TOKEN` must be exported in your terminal; never paste it in chat.

```bash
cd 04-hetzner-terraform   # from the repo root
terraform init
terraform fmt -check
terraform validate
terraform plan
```

Review the plan and price before `terraform apply`; don't apply if it exceeds the cap or hasn't been approved.

```bash
terraform output -raw homeserver_url
terraform output -raw registration_token
```

## Create a Matrix account

Use the Element client at `http://localhost:8080` and choose **Create account**.
Set the homeserver URL to the value from `terraform output -raw homeserver_url`,
then enter a username, password and the registration token from
`terraform output -raw registration_token`. Keep the token private. The Matrix
ID uses the server's IP, for example `@alice:49.13.150.188`.

The local Element client allows a custom homeserver. An HTTPS-hosted browser
client may block this plain-HTTP server; use an HTTP-served client.

From the project root, use `terraform -chdir=04-hetzner-terraform ...`.

## Cleanup

Destroys **both** Hetzner VMs (scenarios 4 and 5), their firewalls and all
Matrix accounts/data on them. This also stops their cloud charges. Back up
anything you need, review the plan, and confirm only when you intend to delete
both servers:

```bash
terraform destroy
```

If the removed Ansible configuration still has a VM tracked in Terraform
state, Terraform may also propose deleting it. Inspect the plan carefully
before confirming; do not apply a plan that would remove resources you want
to keep.
