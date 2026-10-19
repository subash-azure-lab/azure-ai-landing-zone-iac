variable "name" {
  description = "Name of the network security group"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group that will hold the NSG"
  type        = string
}

variable "tags" {
  description = "Tags applied to the NSG"
  type        = map(string)
  default     = {}
}

variable "rules" {
  description = "Custom security rules. Empty means only Azure's default rules apply."
  type = list(object({
    name                         = string
    priority                     = number
    direction                    = string
    access                       = string
    protocol                     = string
    source_port_range            = optional(string, "*")
    destination_port_ranges      = list(string)
    source_address_prefix        = string
    destination_address_prefixes = optional(list(string))
    destination_address_prefix   = optional(string)
  }))
  default = []
}
