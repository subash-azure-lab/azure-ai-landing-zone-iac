variable "subscription_id" {
  description = "Azure subscription to deploy into"
  type        = string
}

variable "location" {
  description = "Azure region"
  type        = string
  default     = "eastus"
}

variable "environment" {
  description = "Environment name, used in tags and resource names"
  type        = string
  default     = "dev"
}

variable "cost_center" {
  description = "CostCenter tag required by policy"
  type        = string
  default     = "AI-Platform"
}
