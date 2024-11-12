# *********************************************************
# VIRTUAL NETWORK
# *********************************************************

locals {
  use_existing_vnet = length(var.existing_vnet_name) > 0 && length(var.existing_vnet_rg_name) > 0 ? true : false # If existing_vnet_name & existing_vnet_rg_name set then true else false
}

# ---------------------------------------------------------
# Data VNet
# ---------------------------------------------------------

data "azurerm_virtual_network" "vnet" {
  count = local.use_existing_vnet ? 1 : 0

  name                = var.existing_vnet_name
  resource_group_name = var.existing_vnet_rg_name
}

# ---------------------------------------------------------
# Create VNet
# ---------------------------------------------------------

resource "azurerm_virtual_network" "vnet" {
  count = local.use_existing_vnet ? 0 : 1

  name                = "${var.vrf}-${var.env_name}-${var.deployment_region_friendly}-${var.descriptor}-VNET"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
  address_space       = var.address_space
  dns_servers         = var.dns_servers
}

# ---------------------------------------------------------
# Create Subnets
# ---------------------------------------------------------

resource "azurerm_subnet" "subnet" {
  for_each = var.subnets

  name                 = each.key
  resource_group_name  = local.use_existing_vnet ? data.azurerm_virtual_network.vnet[0].resource_group_name : azurerm_resource_group.rg.name
  virtual_network_name = local.use_existing_vnet ? data.azurerm_virtual_network.vnet[0].name : azurerm_virtual_network.vnet[0].name
  address_prefixes     = [each.value.cidr]

  private_endpoint_network_policies = "Enabled"
}