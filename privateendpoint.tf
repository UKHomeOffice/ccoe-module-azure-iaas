# *********************************************************
# PRIVATE ENDPOINTS
# *********************************************************

# ---------------------------------------------------------
# Create Private Endpoints - Storage Accounts
# ---------------------------------------------------------

resource "azurerm_private_endpoint" "private-endpoint" {
    for_each = merge([ for name, sadetails in var.storage_accounts : { for subresource, pepdetails in sadetails.private_endpoints : "${name}-${subresource}" => merge(pepdetails, { "name" = name, "subresource" = subresource }) } if sadetails.private_endpoints != null ]...)

    name                = "${each.value.name}-${each.value.subresource}-PEP"
    resource_group_name = azurerm_resource_group.rg.name
    location            = azurerm_resource_group.rg.location
    tags                = var.tags
    subnet_id           = azurerm_subnet.subnet[each.value.subnet].id

    custom_network_interface_name = "${each.value.name}-${each.value.subresource}-NIC"

    private_service_connection {
        name                           = "${each.value.name}-${each.value.subresource}-PEP-PrivateServiceConn"
        private_connection_resource_id = azurerm_storage_account.storage-account[each.value.name].id
        subresource_names              = [each.value.subresource]
        is_manual_connection           = false
    }

    ip_configuration {
      name               = "${each.value.name}-${each.value.subresource}-PEP-IPConfig"
      private_ip_address = each.value.ip
      subresource_name   = each.value.subresource
    }
}