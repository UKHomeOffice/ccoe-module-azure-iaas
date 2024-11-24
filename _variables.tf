# *********************************************************
# VARIABLES
# *********************************************************

# ---------------------------------------------------------
# Environment & Region
# ---------------------------------------------------------

variable "vrf" {
  type        = string
  description = "The name of the VRF being deployed. e.g HO1, HO3"
  nullable    = false
}

variable "env_name" {
  type        = string
  description = "The name of the environemnt being deployed. e.g Prd, NPA"
  nullable    = false
}

variable "deployment_region" {
  type        = string
  description = "The name of the region being deployed to. e.g uksouth"
  nullable    = false
}

variable "deployment_region_friendly" {
  type        = string
  description = "The friendly name of the region being deployed to. e.g UKSouth"
  nullable    = false
}

variable "descriptor" {
  type        = string
  description = "The descriptor of the project being deployed. Used in all resource names. e.g Sailpoint"
  nullable    = false
}

# ---------------------------------------------------------
# Tags
# ---------------------------------------------------------

variable "tags" {
  type = object({
    CostCentre = string
    Env        = string
    Owner      = string
    Repository = string
    Script     = string
    Service    = string
    Project    = string
    ProjectID  = string
  })
  description = "Azure tags to be applied to all resources inc RG."
  nullable    = false
}

# ---------------------------------------------------------
# Networking
# ---------------------------------------------------------

variable "existing_vnet_name" {
  type        = string
  description = "If using an existing VNet then set this to the VNet name."
  default     = ""
}

variable "existing_vnet_rg_name" {
  type        = string
  description = "If using an existing VNet then set this to the VNet RG name."
  default     = ""
}

variable "address_space" {
  type        = list(string)
  description = "Overall address space to be used for VNet. Subnets will be within this. Only relevant if vnet_id is NOT specified."
  default     = []
}

variable "dns_servers" {
  type        = list(string)
  description = "DNS servers to be used by the VNet. Only relevant if vnet_id is NOT specified."
  default     = []
}

variable "subnets" {
  type = map(object({
    cidr = string
    nsg  = optional(string, "")
  }))
  description = "Subnets to be created in the VNet."
  nullable    = false
}

# ---------------------------------------------------------
# Virtual Machines
# ---------------------------------------------------------

variable "admin_username" {
  type        = string
  description = "Admin username for virtual machines."
}

variable "windows_server_sku" {
  type        = string
  description = "SKU of Windows to use e.g 2019-Datacenter"
  default     = "2019-Datacenter"
}

variable "virtual_machines" {
  type = map(map(object({
    size           = string
    subnet         = string
    ip             = string
    is_windows     = optional(bool, true)
    user_data      = optional(string, "") # Filepath to user data
    backup_policy  = optional(string, "Default")
    nsg            = optional(string, "")
    disk_set       = optional(string, "")
    ssh_public_key = optional(string, "") # This should be a path to a local file containing the public key
    image_id       = optional(string, "")
    image_ref = optional(object({
      publisher = string
      offer     = string
      sku       = string
      version   = string
    }), null)
  })))
  description = "Virtual machines to be deployed and their parameters."
  nullable    = false
}

# ---------------------------------------------------------
# Disk Sets
# ---------------------------------------------------------

variable "disk_sets" {
  type = map(map(object({
    lun  = number
    size = number
  })))
  description = "Disk sets which can be linked to VMs."
}

# ---------------------------------------------------------
# Storage Accounts
# ---------------------------------------------------------

variable "storage_accounts" {
  type = map(object({
    containers = optional(map(object({
      access_type = optional(string, "private")
    })), {})
    shares = optional(map(object({
      quota       = number
      access_type = optional(string, "private")
    })), {})
    private_endpoints = optional(map(object({
      subnet = string
      ip     = string
    })), {})
  }))
  description = "Storage accounts to be created."
}

# ---------------------------------------------------------
# Network Security Groups
# ---------------------------------------------------------

variable "baseline_cidrs" {
  type = object({
    management         = optional(list(string), [])
    domain_controllers = optional(list(string), [])
    proxy              = optional(list(string), [])
    snmp               = optional(list(string), [])
    ntp                = optional(list(string), [])
    sccm               = optional(list(string), [])
    scom               = optional(list(string), [])
    package_repo       = optional(list(string), [])
    kms                = optional(list(string), [])
  })
  description = "CIDRs to be used in the baseline rules. If none specified a wildcard will be used."
}

variable "network_security_groups" {
  type = map(object({
    baselines = optional(list(string), [""])
    rules = optional(map(object({
      priority                     = number
      direction                    = string
      access                       = string
      protocol                     = string
      source_port_range            = optional(string, "")
      source_port_ranges           = optional(list(string), [])
      destination_port_range       = optional(string, "")
      destination_port_ranges      = optional(list(string), [])
      source_address_prefix        = optional(string, "")
      source_address_prefixes      = optional(list(string), [])
      destination_address_prefix   = optional(string, "")
      destination_address_prefixes = optional(list(string), [])
    })), {})
  }))
  description = "NSGs to be created with rules."
}

# ---------------------------------------------------------
# Backup Policies
# ---------------------------------------------------------

variable "backup_policies" {
  type = map(object({
    frequency                      = string
    time                           = string
    hour_interval                  = optional(number, null)
    hour_duration                  = optional(number, null)
    weekdays                       = optional(list(string), [])
    instant_restore_retention_days = optional(number, null)
    retention_daily = optional(object({
      count = optional(number, 0)
    }), {})
    retention_weekly = optional(object({
      count    = optional(number, 0)
      weekdays = optional(list(string), null)
    }), {})
    retention_monthly = optional(object({
      count             = optional(number, 0)
      weekdays          = optional(list(string), [])
      weeks             = optional(list(string), [])
      days              = optional(list(number), [])
      include_last_days = optional(bool, null)
    }), {})
    retention_yearly = optional(object({
      count             = optional(number, 0)
      months            = optional(list(string), [])
      weekdays          = optional(list(string), [])
      weeks             = optional(list(string), [])
      days              = optional(list(number), [])
      include_last_days = optional(bool, null)
    }), {})
  }))
  description = "Custom backup policies to be created."
}