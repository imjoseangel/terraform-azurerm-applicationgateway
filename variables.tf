variable "name" {
  description = "Name of Application Gateway service."
  type        = string
}

variable "pip_name" {
  description = "Name of Public IP for the Application Gateway service."
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
  default     = null
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

variable "identity_type" {
  description = "Type type of identity used for the managed cluster. Possible values are 'SystemAssigned' and 'UserAssigned'. If 'UserAssigned' is set, a 'user_assigned_identity_id' must be set as well."
  type        = string
  default     = "SystemAssigned"
}

variable "user_assigned_identity_id" {
  description = "(Optional) the ID of a user assigned identity"
  type        = list(string)
  default     = null
}

variable "tags" {
  description = "Tags to apply to all resources created."
  type        = map(string)
  default     = {}
}

variable "min_capacity" {
  description = "(Required) Minimum capacity for autoscaling. Accepted values are in the range 0 to 100."
  type        = number
  default     = null
}

variable "max_capacity" {
  description = "(Optional) Maximum capacity for autoscaling. Accepted values are in the range 2 to 125"
  type        = number
  default     = 2
}

variable "fqdns" {
  description = "(Optional) A list of FQDN's which should be part of the Backend Address Pool."
  type        = list(string)
  default     = []
}

variable "ip_addresses" {
  description = "(Optional) A list of IP Addresses which should be part of the Backend Address Pool."
  type        = list(string)
  default     = []
}

variable "key_vault_secret_id" {
  description = "(Optional) Secret Id of (base-64 encoded unencrypted pfx) Secret or Certificate object stored in Azure KeyVault. You need to enable soft delete for keyvault to use this feature. Required if data is not set."
  type        = string
  default     = ""
}

variable "ssl_certificate_name" {
  description = "(Required) The Name of the SSL certificate that is unique within this Application Gateway"
  type        = string
  default     = "ssl-certificate"
}

variable "host_names" {
  description = "(Optional) A list of Hostname(s) should be used for this HTTP Listener. It allows special wildcard characters."
  type        = list(string)
  default     = []
}
