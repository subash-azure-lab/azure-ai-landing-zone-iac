variable "name" {
  description = "Name of this peering, e.g. hub-to-spoke1"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group of the local VNet"
  type        = string
}

variable "virtual_network_name" {
  description = "Name of the local VNet that owns this peering"
  type        = string
}

variable "remote_virtual_network_id" {
  description = "Resource ID of the remote VNet"
  type        = string
}

variable "allow_forwarded_traffic" {
  description = "Allow traffic forwarded by an appliance (needed for hub firewall designs)"
  type        = bool
  default     = true
}
