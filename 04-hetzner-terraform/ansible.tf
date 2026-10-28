variable "ansible_ssh_public_key_path" {
  description = "Public SSH key installed on the Ansible target server (the playbook connects over SSH)."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"
}

resource "hcloud_ssh_key" "ansible" {
  name       = "matrix-ansible"
  public_key = file(pathexpand(var.ansible_ssh_public_key_path))
}

resource "hcloud_firewall" "ansible" {
  name = "matrix-ansible-test"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "22"
    source_ips = var.allowed_client_ips
  }

  # Let's Encrypt, HTTPS clients and federation must reach these from anywhere.
  dynamic "rule" {
    for_each = ["80", "443", "8448"]
    content {
      direction  = "in"
      protocol   = "tcp"
      port       = rule.value
      source_ips = ["0.0.0.0/0", "::/0"]
    }
  }
}

resource "hcloud_server" "ansible" {
  name        = "matrix-ansible-test"
  server_type = var.server_type
  image       = "ubuntu-24.04"
  location    = var.location
  ssh_keys    = [hcloud_ssh_key.ansible.id]
  firewall_ids = [
    hcloud_firewall.ansible.id,
  ]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }
}

locals {
  # sslip.io resolves <a-b-c-d>.sslip.io and every subdomain to a.b.c.d, so Let's Encrypt works without owning a domain.
  ansible_base_domain = "${replace(hcloud_server.ansible.ipv4_address, ".", "-")}.sslip.io"
}

output "ansible_server_ipv4" {
  description = "Public IPv4 of the Ansible target server."
  value       = hcloud_server.ansible.ipv4_address
}

output "ansible_base_domain" {
  description = "Base domain for the playbook (matrix_domain); matrix.<this> and element.<this> resolve to the server."
  value       = local.ansible_base_domain
}
