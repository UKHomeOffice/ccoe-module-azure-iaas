# *********************************************************
# SSH PUBLIC KEYS
# *********************************************************

resource "azurerm_ssh_public_key" "public-key" {
  for_each = { for k, v in local.all_vms : k => v if length(v.ssh_public_key) > 0 }

  name                = "${each.value.name}-SSHKey"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  public_key          = file(each.value.ssh_public_key)
}