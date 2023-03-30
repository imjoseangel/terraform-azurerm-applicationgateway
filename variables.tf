variable "name" {
  description = "Name of Application Gateway service."
  type        = string
}

variable "name" {
  description = "Name of Public IP."
  type        = string
}

variable "create_resource_group" {
  description = "Whether to create resource group and use it for all networking resources"
  default     = true
  type        = bool
}

variable "resource_group_name" {
  description = "A container that holds related resources for an Azure solution"
  default     = "rg-demo-westeurope-01"
  type        = string
}

variable "location" {
  description = "The location/region to keep all your resources. To get the list of all locations with table format from azure cli, run 'az account list-locations -o table'"
  default     = "westeurope"
  type        = string
}

variable "prefix" {
  description = "The prefix for the resources created in the specified Azure Resource Group"
  type        = string
  default     = "default"
}

variable "sku" {
  description = "(Required) The Name of the SKU to use for this Application Gateway. Possible values are Standard_v2, and WAF_v2"
  type        = string
  default     = "Standard_v2"

  validation {
    condition     = can(regex("Standard_v2|WAF_v2", var.sku))
    error_message = "ERROR: Invalid SKU Tier must be of either Standard_v2 or WAF_v2."
  }
}

variable "sku_capacity" {
  description = "(Required) The Capacity of the SKU to use for this Application Gateway. When using a V1 SKU this value must be between 1 and 32, and 1 to 125 for a V2 SKU."
  type        = number
  default     = 1
}

variable "vnet_subnet_id" {
  description = "(Required) The ID of the Subnet which the Application Gateway should be connected to."
  type        = string
}

variable "waf_enabled" {
  description = "Is the Web Application Firewall be enabled?"
  default     = false
  type        = bool
}

variable "waf_firewall_mode" {
  description = "(Required) The Web Application Firewall Mode. Possible values are Detection and Prevention."
  type        = string
  default     = "Detection"
}

variable "tags" {
  description = "Tags to apply to all resources created."
  type        = map(string)
  default     = {}
}
