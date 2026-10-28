resource "random_password" "native_registration_token" {
  length  = 40
  special = false
}

resource "hcloud_firewall" "native" {
  name = "matrix-native-test"

  rule {
    direction  = "in"
    protocol   = "tcp"
    port       = "8008"
    source_ips = var.allowed_client_ips
  }
}

resource "hcloud_server" "native" {
  name        = "matrix-native-test"
  server_type = var.server_type
  image       = "ubuntu-24.04"
  location    = var.location
  firewall_ids = [
    hcloud_firewall.native.id,
  ]

  public_net {
    ipv4_enabled = true
    ipv6_enabled = false
  }

  user_data = templatefile("${path.module}/cloud-init-native.yaml.tftpl", {
    registration_token = random_password.native_registration_token.result
    tuwunel_version    = var.tuwunel_version
  })
}

output "native_homeserver_url" {
  description = "HTTP URL for the native (systemd) Tuwunel test server."
  value       = "http://${hcloud_server.native.ipv4_address}:8008"
}

output "native_registration_token" {
  description = "Registration token for the native Tuwunel server. Keep it private."
  value       = random_password.native_registration_token.result
  sensitive   = true
}
