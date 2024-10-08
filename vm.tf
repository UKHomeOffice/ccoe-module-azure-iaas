# *********************************************************
# VIRTUAL MACHINES
# *********************************************************

locals {
    all_vms = merge([ for zone, vms in var.virtual_machines : { for vmname, vmdetails in vms : "${zone}-${vmname}" => merge(vmdetails, { "name" = vmname, "zone" = zone, "disks" = length(vmdetails.disk_set) > 0 ? var.disk_sets[vmdetails.disk_set] : {} }) } ]...)

    # This is a sample of what the above should output        
    # all_vms = {
    #     "1-SERVERNAME" = {
    #         is_windows = true
    #         size       = "Standard_A4_v2"
    #         subnet     = "Frontend"
    #         ip         = "10.10.10.1"
    #         disk_set   = "app"
    #         name       = "SERVERNAME"
    #         zone       = 1
    #         disks      = {
    #             page_file = {
    #                 lun  = 35,
    #                 size = 12
    #             }
    #         }
    #     }
    # }

    all_vm_resources = merge(azurerm_windows_virtual_machine.virtual-machine-windows, azurerm_linux_virtual_machine.virtual-machine-linux)
}

# ---------------------------------------------------------
# Generate Random Password
# ---------------------------------------------------------

resource "random_password" "password" {
  length           = 32
  special          = false
}

# ---------------------------------------------------------
# Create VMs - Windows
# ---------------------------------------------------------

resource "azurerm_windows_virtual_machine" "virtual-machine-windows" {
    for_each            = { for k, v in local.all_vms : k => v if v.is_windows }

    name                = each.value.name
    tags                = var.tags
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    size                = each.value.size
    admin_username      = var.admin_username
    admin_password      = random_password.password.result
    zone                = each.value.zone
    user_data           = length(each.value.user_data) > 0 ? filebase64(each.value.user_data) : null

    network_interface_ids = [
        azurerm_network_interface.nic[each.key].id,
    ]

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.bootdiag.primary_blob_endpoint
    }

    os_disk {
        name                 = "${each.value.name}-OSDisk"
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    source_image_reference {
        publisher = "MicrosoftWindowsServer"
        offer     = "WindowsServer"
        sku       = "2022-Datacenter"
        version   = "latest"
    }
}

# ---------------------------------------------------------
# Create VMs - Linux
# ---------------------------------------------------------

resource "azurerm_linux_virtual_machine" "virtual-machine-linux" {
    for_each            = { for k, v in local.all_vms : k => v if v.is_windows == false }

    name                = each.value.name
    tags                = var.tags
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name
    size                = each.value.size
    admin_username      = var.admin_username
    admin_password      = length(each.value.ssh_public_key) > 0 ? null : random_password.password.result
    zone                = each.value.zone
    user_data           = length(each.value.user_data) > 0 ? filebase64(each.value.user_data) : null

    disable_password_authentication = length(each.value.ssh_public_key) > 0 ? true : false

    network_interface_ids = [
        azurerm_network_interface.nic[each.key].id,
    ]

    boot_diagnostics {
        storage_account_uri = azurerm_storage_account.bootdiag.primary_blob_endpoint
    }

    os_disk {
        name                 = "${each.value.name}-OSDisk"
        caching              = "ReadWrite"
        storage_account_type = "Standard_LRS"
    }

    dynamic "admin_ssh_key" {
        for_each = [ for k in [each.key] : k if length(each.value.ssh_public_key) > 0 ] # Only do this if ssh_public_key given
        content {
            username   = var.admin_username
            public_key = azurerm_ssh_public_key.public-key[each.key].public_key
        }
    }

    dynamic "source_image_reference" {
        for_each = [ for k in [each.key] : k if length(each.value.image_id) == 0 ] # Only do this if image_id NOT given
        content {
            publisher = each.value.image_ref.publisher
            offer     = each.value.image_ref.offer
            sku       = each.value.image_ref.sku
            version   = each.value.image_ref.version
        }
    }

    source_image_id = length(each.value.image_id) == 0 ? null : each.value.image_id
}

# ---------------------------------------------------------
# Create NICs
# ---------------------------------------------------------

resource "azurerm_network_interface" "nic" {
    for_each            = local.all_vms
    
    name                = "${each.value.name}-NIC"
    tags                = var.tags
    location            = azurerm_resource_group.rg.location
    resource_group_name = azurerm_resource_group.rg.name

    ip_configuration {
        name                          = "internal"
        subnet_id                     = azurerm_subnet.subnet[each.value.subnet].id
        private_ip_address_allocation = "Static"
        private_ip_address            = each.value.ip
    }
}