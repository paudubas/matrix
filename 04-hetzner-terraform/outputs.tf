output "homeserver_url" {
  description = "HTTP URL for the IP-only Matrix test server."
  value       = "http://${hcloud_server.matrix.ipv4_address}:8008"
}

output "server_ipv4" {
  description = "Hetzner-assigned public IPv4 address."
  value       = hcloud_server.matrix.ipv4_address
}

output "registration_token" {
  description = "Generated Tuwunel registration token. Keep it private."
  value       = random_password.registration_token.result
  sensitive   = true
}
