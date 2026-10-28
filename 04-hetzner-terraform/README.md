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

An HTTPS-hosted browser client may block an HTTP homeserver; use an HTTP-served client. Data lives on the VM disk and is lost on destroy.

From the project root, use `terraform -chdir=04-hetzner-terraform ...`.

## Cleanup

Destroys **both** VMs (scenarios 4 and 5):

```bash
terraform destroy
```
