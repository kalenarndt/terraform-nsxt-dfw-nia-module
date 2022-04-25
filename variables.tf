variable "services" {
  description = "Consul services monitored by Consul Terraform Sync"
  type = map(
    object({
      id        = string
      name      = string
      kind      = string
      address   = string
      port      = number
      meta      = map(string)
      tags      = list(string)
      namespace = string
      status    = string

      node                  = string
      node_id               = string
      node_address          = string
      node_datacenter       = string
      node_tagged_addresses = map(string)
      node_meta             = map(string)

      cts_user_defined_meta = map(string)
    })
  )
}

variable "cts_prefix" {
  type        = string
  description = "(Optional) Prefix that will be applied to all objects created via Consul-Terraform-Sync"
  default     = "cts-"
}

variable "default_action" {
  type        = string
  description = "Default action for the rule at the bottom of the section created by Consul-Terraform-Sync. "
  validation {
    condition     = var.default_action != "DROP" || var.default_action != "ALLOW" || var.default_action != "REJECT"
    error_message = "The variable default_action must be \"DROP\", \"ALLOW\", or \"REJECT\"."
  }
  default = "ALLOW"
}