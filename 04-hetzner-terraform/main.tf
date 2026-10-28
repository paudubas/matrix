terraform {
  required_providers {
    hcloud = {
      source  = "hetznercloud/hcloud"
      version = ">= 1.50, < 2.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.6, < 4.0"
    }
  }
}

provider "hcloud" {}

resource "random_password" "registration_token" {
  length  = 40
  special = false
}

resource "hcloud_firewall" "matrix" {
  name = "matrix-ip-test"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "8008"
    source_ips = var.allowed_client_ips
  }
}

resource "hcloud_server" "matrix" {
  name        = "matrix-ip-test"
  server_type = var.server_type
  image       = "ubuntu-24.04"
  location    = var.location
  firewall_ids = [
    hcloud_firewall.matrix.id,
  ]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  user_data = templatefile("${path.module}/cloud-init.yaml.tftpl", {
    registration_token = random_password.registration_token.result
  })
}
