# *********************************************************
# DISKS
# *********************************************************

locals {
  all_disks = merge([for vmkey, vmdetails in local.all_vms : { for diskname, diskdetails in vmdetails.disks : "${vmdetails.name}-${diskname}" => merge(diskdetails, { "name" = diskname, "vmkey" = vmkey, "vm" = vmdetails }) }]...)
}

# ---------------------------------------------------------
# Create Disks
# ---------------------------------------------------------

resource "azurerm_managed_disk" "disk" {
  for_each = local.all_disks

  name                 = "${each.value.vm.name}-${each.value.name}-Disk"
  tags                 = var.tags
  location             = azurerm_resource_group.rg.location
  resource_group_name  = azurerm_resource_group.rg.name
  storage_account_type = "StandardSSD_LRS"
  disk_size_gb         = each.value.size
  create_option        = "Empty"
  zone                 = each.value.vm.zone
}

# ---------------------------------------------------------
# Attach Disks - Windows
# ---------------------------------------------------------

resource "azurerm_virtual_machine_data_disk_attachment" "disk-attach-windows" {
  for_each = local.all_disks

  virtual_machine_id = each.value.vm.is_windows ? azurerm_windows_virtual_machine.virtual-machine-windows[each.value.vmkey].id : azurerm_linux_virtual_machine.virtual-machine-linux[each.value.vmkey].id
  managed_disk_id    = azurerm_managed_disk.disk[each.key].id
  lun                = each.value.lun
  caching            = "ReadWrite"
}