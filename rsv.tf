# *********************************************************
# RECOVERY SERVICES VAULT
# *********************************************************

# ---------------------------------------------------------
# Create RSV
# ---------------------------------------------------------

resource "azurerm_recovery_services_vault" "rsv" {
  name                = "${var.vrf}-${var.env_name}-${var.deployment_region_friendly}-${var.descriptor}-RSV"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags
  sku                 = "Standard"

  soft_delete_enabled = true
}

# ---------------------------------------------------------
# Define Standard Backup Policy
# ---------------------------------------------------------

locals{
  default_vm_backup_policy = {
    "Default" = {
      frequency                      = "Daily"
      time                           = "03:00"
      hour_interval                  = null
      hour_duration                  = null
      weekdays                       = []
      instant_restore_retention_days = 7
      retention_daily = {
        count = 30
      }
      retention_weekly = {
        count    = 7
        weekdays = ["Saturday"]
      }
      retention_monthly = {
        count = 0
      }
      retention_yearly  = {
        count = 0
      }
    }
  }
}

# ---------------------------------------------------------
# Create Backup Policies
# ---------------------------------------------------------

resource "azurerm_backup_policy_vm" "vm-backup-policy" {
  for_each = merge(local.default_vm_backup_policy, var.backup_policies)

  name                = each.key
  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv.name

  policy_type                    = "V2"
  timezone                       = "GMT Standard Time"
  instant_restore_retention_days = each.value.instant_restore_retention_days

  instant_restore_resource_group {
    prefix = "${var.vrf}-${var.env_name}-${var.deployment_region_friendly}-${var.descriptor}Backup"
    suffix = "-RG"
  }

  backup {
    frequency     = each.value.frequency
    time          = each.value.time
    hour_duration = each.value.hour_duration
    hour_interval = each.value.hour_interval
    weekdays      = each.value.weekdays
  }

  dynamic "retention_daily" {
    for_each = [ for k in [each.value.retention_daily] : k if each.value.retention_daily.count > 0 ] # Only do this if count is greater than 0

    content {
      count = each.value.retention_daily.count
    }
  }

  dynamic "retention_weekly" {
    for_each = [ for k in [each.value.retention_weekly] : k if each.value.retention_weekly.count > 0 ] # Only do this if count is greater than 0

    content {
      count    = each.value.retention_weekly.count
      weekdays = each.value.retention_weekly.weekdays
    }
  }

  dynamic "retention_monthly" {
    for_each = [ for k in [each.value.retention_monthly] : k if each.value.retention_monthly.count > 0 ] # Only do this if count is greater than 0

    content {
      count             = each.value.retention_monthly.count
      weekdays          = each.value.retention_monthly.weekdays
      weeks             = each.value.retention_monthly.weeks
      days              = each.value.retention_monthly.days
      include_last_days = each.value.retention_monthly.include_last_days
    }
  }

  dynamic "retention_yearly" {
    for_each = [ for k in [each.value.retention_yearly] : k if each.value.retention_yearly.count > 0 ] # Only do this if count is greater than 0

    content {
      count             = each.value.retention_yearly.count
      months            = each.value.retention_yearly.months 
      weekdays          = each.value.retention_yearly.weekdays
      weeks             = each.value.retention_yearly.weeks
      days              = each.value.retention_yearly.days
      include_last_days = each.value.retention_yearly.include_last_days
    }
  }
}

# ---------------------------------------------------------
# Enroll VMs To Policies
# ---------------------------------------------------------

resource "azurerm_backup_protected_vm" "vm-backup" {
  for_each = local.all_vms

  resource_group_name = azurerm_resource_group.rg.name
  recovery_vault_name = azurerm_recovery_services_vault.rsv.name
  source_vm_id        = local.all_vm_resources[each.key].id
  backup_policy_id    = azurerm_backup_policy_vm.vm-backup-policy[each.value.backup_policy].id
}