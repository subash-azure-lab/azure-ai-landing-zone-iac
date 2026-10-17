variable "name" {
  description = "Name of the route table"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
}

variable "resource_group_name" {
  description = "Resource group the route table is created in"
  type        = string
}

variable "firewall_private_ip" {
  description = "Private IP of the firewall used as the next hop"
  type        = string
}

variable "tags" {
  description = "Tags applied to the route table"
  type        = map(string)
  default     = {}
}
