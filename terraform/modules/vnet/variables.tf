variable "name" {
  description = "Name of the virtual network"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the VNet is created in"
  type        = string
}

variable "address_prefix" {
  description = "Address space of the VNet, e.g. 10.1.0.0/16"
  type        = string
}

variable "subnets" {
  description = "Subnets to create. Each item: { name, prefix }"
  type = list(object({
    name   = string
    prefix = string
  }))
}

variable "nsg_ids" {
  description = "Map of subnet name to the ID of the NSG to attach. Subnets not listed get no NSG."
  type        = map(string)
  default     = {}
}

variable "tags" {
  description = "Tags applied to the VNet"
  type        = map(string)
  default     = {}
}
