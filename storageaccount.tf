# *********************************************************
# STORAGE ACCOUNTS
# *********************************************************

# ---------------------------------------------------------
# Boot Diagnostics Storage Account
# ---------------------------------------------------------

resource "azurerm_storage_account" "bootdiag" {
  # The substr functions here assume the environment name is no more than 4 chars and the descriptor is no more than 12 chars.
  # This ensures that the naming fits within the 24 char limit along with the lower() function for lowercase.
  name                     = lower("hobootdiag${substr(var.descriptor, 0, 12)}${substr(var.env_name, 0, 4)}")
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  tags                     = var.tags
  account_tier             = "Standard"
  account_replication_type = "LRS"

  allow_nested_items_to_be_public = false
}

# ---------------------------------------------------------
# Boot Diagnostics Storage Account - Container
# ---------------------------------------------------------

resource "azurerm_storage_container" "bootdiag-container" {
  name                  = "bootdiag"
  storage_account_name  = azurerm_storage_account.bootdiag.name
  container_access_type = "private"
}

# ---------------------------------------------------------
# User Defined Storage Accounts
# ---------------------------------------------------------

resource "azurerm_storage_account" "storage-account" {
  for_each = var.storage_accounts

  name                     = each.key
  resource_group_name      = azurerm_resource_group.rg.name
  location                 = azurerm_resource_group.rg.location
  tags                     = var.tags
  account_tier             = "Standard"
  account_replication_type = "GZRS"

  # If storage account is using private endpoint(s) then dont allow public access / items
  public_network_access_enabled   = length(each.value.private_endpoints) > 0 ? false : true
  allow_nested_items_to_be_public = length(each.value.private_endpoints) > 0 ? false : true
}

# ---------------------------------------------------------
# User Defined Storage Accounts - Containers
# ---------------------------------------------------------

locals {
  containers = merge([for saname, sadetails in var.storage_accounts : { for cname, cdetails in sadetails.containers : "${saname}-${cname}" => merge(cdetails, { "storage_account" = saname, "container" = cname }) }]...)
}

resource "azurerm_storage_container" "storage-account-container" {
  for_each = local.containers

  name                  = each.value.container
  storage_account_name  = azurerm_storage_account.storage-account[each.value.storage_account].name
  container_access_type = each.value.access_type
}

# ---------------------------------------------------------
# User Defined Storage Accounts - Shares
# ---------------------------------------------------------

locals {
  shares = merge([for saname, sadetails in var.storage_accounts : { for sname, sdetails in sadetails.shares : "${saname}-${sname}" => merge(sdetails, { "storage_account" = saname, "share" = sname }) }]...)
}

resource "azurerm_storage_share" "storage-account-share" {
  for_each = local.shares

  name                 = each.value.share
  storage_account_name = azurerm_storage_account.storage-account[each.value.storage_account].name
  quota                = each.value.quota
}