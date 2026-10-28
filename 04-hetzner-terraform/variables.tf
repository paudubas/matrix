variable "server_type" {
  description = "Hetzner shared server size. CX23 is a small general-purpose test VM."
  type        = string
  default     = "cx23"
}

variable "location" {
  description = "Hetzner Cloud location."
  type        = string
  default     = "nbg1"
}

variable "tuwunel_version" {
  description = "Tuwunel release tag installed natively on the second server."
  type        = string
  default     = "v1.9.4"
}

variable "allowed_client_ips" {
  description = "IPv4 CIDRs allowed to connect to the HTTP homeserver. Set in terraform.tfvars (git-ignored)."
  type        = list(string)

  validation {
    condition     = length(var.allowed_client_ips) > 0
    error_message = "Set at least one client IPv4 CIDR so the HTTP homeserver is not exposed publicly."
  }
}
