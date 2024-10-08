# *********************************************************
# OUTPUTS
# *********************************************************

# ---------------------------------------------------------
# Variables
# ---------------------------------------------------------

# ---------------------------------------------------------
# Environment & Region
# ---------------------------------------------------------

output "var_vrf" {
  value = var.vrf
}

output "var_env_name" {
  value = var.env_name
}

output "var_deployment_region" {
  value = var.deployment_region
}

output "var_deployment_region_friendly" {
  value = var.deployment_region_friendly
}

output "var_descriptor" {
  value = var.descriptor
}

# ---------------------------------------------------------
# Tags
# ---------------------------------------------------------

output "var_tags" {
  value = var.tags
}

# ---------------------------------------------------------
# Networking
# ---------------------------------------------------------

output "var_existing_vnet_name" {
  value = var.existing_vnet_name
}

output "var_existing_vnet_rg_name" {
  value = var.existing_vnet_rg_name
}

output "var_address_space" {
  value = var.address_space
}

output "var_dns_servers" {
  value = var.dns_servers
}

output "var_subnets" {
  value = var.subnets
}

# ---------------------------------------------------------
# Virtual Machines
# ---------------------------------------------------------

output "var_virtual_machines" {
  value = var.virtual_machines
}

# ---------------------------------------------------------
# Disk Sets
# ---------------------------------------------------------

output "var_disk_sets" {
  value = var.disk_sets
}

# ---------------------------------------------------------
# Storage Accounts
# ---------------------------------------------------------

output "var_storage_accounts" {
  value = var.storage_accounts
}

# ---------------------------------------------------------
# Network Security Groups
# ---------------------------------------------------------

output "var_baseline_cidrs" {
  value = var.baseline_cidrs
}

output "var_network_security_groups" {
  value = var.network_security_groups
}

# ---------------------------------------------------------
# Resources
# ---------------------------------------------------------

# ---------------------------------------------------------
# Resource Group
# ---------------------------------------------------------

output "rg" {
  value = azurerm_resource_group.rg
}

# ---------------------------------------------------------
# Networking
# ---------------------------------------------------------

output "vnet" {
  value = local.use_existing_vnet ? data.azurerm_virtual_network.vnet[0] : azurerm_virtual_network.vnet[0]
}

output "subnets" {
  value = azurerm_subnet.subnet
}

# ---------------------------------------------------------
# Virtual Machines
# ---------------------------------------------------------

output "all_virtual_machines" {
  value = local.all_vms
}

output "virtual_machines" {
  value = local.all_vm_resources
}

output "windows_virtual_machines" {
  value = azurerm_windows_virtual_machine.virtual-machine-windows
}

output "linux_virtual_machines" {
  value = azurerm_linux_virtual_machine.virtual-machine-linux
}

# ---------------------------------------------------------
# NICs
# ---------------------------------------------------------

output "nics" {
  value = azurerm_network_interface.nic
}

# ---------------------------------------------------------
# Disk Sets
# ---------------------------------------------------------

output "all_disks" {
  value = local.all_disks
}

output "disks" {
  value = azurerm_managed_disk.disk
}

# ---------------------------------------------------------
# Storage Accounts
# ---------------------------------------------------------

output "storage_accounts" {
  value = azurerm_storage_account.storage-account
}

# ---------------------------------------------------------
# Network Security Groups
# ---------------------------------------------------------

output "network_security_groups" {
  value = azurerm_network_security_group.network-security-group
}

# ---------------------------------------------------------
# Private Endpoints
# ---------------------------------------------------------

output "private_endpoints" {
  value = azurerm_private_endpoint.private-endpoint
}

# ---------------------------------------------------------
# SSH Public Keys
# ---------------------------------------------------------

output "ssh_public_keys" {
  value = azurerm_ssh_public_key.public-key
}

# ---------------------------------------------------------
# Recovery Sevices Vault
# ---------------------------------------------------------

output "recovery_services_vault" {
  value = azurerm_recovery_services_vault.rsv
}

output "default_vm_backup_policy" {
  value = local.default_vm_backup_policy
}

output "vm_backup_policies" {
  value = azurerm_backup_policy_vm.vm-backup-policy
}