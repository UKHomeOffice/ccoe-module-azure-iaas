# *********************************************************
# NETWORK SECURITY GROUPS
# *********************************************************

# ---------------------------------------------------------
# Baseline Rule Sets
# ---------------------------------------------------------

locals {
  baselines_global = {
    "SNMP-In" = {
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Udp"
      source_port_range          = "*"
      destination_port_ranges    = ["161-162"]
      source_address_prefix      = length(var.baseline_cidrs.snmp) > 0 ? null : "*"
      source_address_prefixes    = length(var.baseline_cidrs.snmp) > 0 ? var.baseline_cidrs.snmp : null
      destination_address_prefix = "*"
    },
    "Proxy-Out" = {
      direction                    = "Outbound"
      access                       = "Allow"
      protocol                     = "Tcp"
      source_port_range            = "*"
      destination_port_ranges      = ["8080"]
      source_address_prefix        = "*"
      destination_address_prefix   = length(var.baseline_cidrs.proxy) > 0 ? null : "*"
      destination_address_prefixes = length(var.baseline_cidrs.proxy) > 0 ? var.baseline_cidrs.proxy : null
    },
    "NTP-Out" = {
      direction                    = "Outbound"
      access                       = "Allow"
      protocol                     = "Udp"
      source_port_range            = "*"
      destination_port_ranges      = ["123"]
      source_address_prefix        = "*"
      destination_address_prefix   = length(var.baseline_cidrs.ntp) > 0 ? null : "*"
      destination_address_prefixes = length(var.baseline_cidrs.ntp) > 0 ? var.baseline_cidrs.ntp : null
    },
    "Domain-Controllers-Out" = {
      direction                    = "Outbound"
      access                       = "Allow"
      protocol                     = "*"
      source_port_range            = "*"
      destination_port_ranges      = ["123", "135", "464", "49152-65535", "389", "636", "3268", "3269", "53", "88", "445"]
      source_address_prefix        = "*"
      destination_address_prefix   = length(var.baseline_cidrs.domain_controllers) > 0 ? null : "*"
      destination_address_prefixes = length(var.baseline_cidrs.domain_controllers) > 0 ? var.baseline_cidrs.domain_controllers : null
    },
    "SCCM-In" = {
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["9", "2701", "3389"]
      source_address_prefix      = length(var.baseline_cidrs.sccm) > 0 ? null : "*"
      source_address_prefixes    = length(var.baseline_cidrs.sccm) > 0 ? var.baseline_cidrs.sccm : null
      destination_address_prefix = "*"
    },
    "SCCM-Out" = {
      direction                    = "Outbound"
      access                       = "Allow"
      protocol                     = "*"
      source_port_range            = "*"
      destination_port_ranges      = ["67-69", "80", "443", "445", "547", "4011", "8005", "8530", "8531", "10123", "63000-64000"]
      source_address_prefix        = "*"
      destination_address_prefix   = length(var.baseline_cidrs.sccm) > 0 ? null : "*"
      destination_address_prefixes = length(var.baseline_cidrs.sccm) > 0 ? var.baseline_cidrs.sccm : null
    },
    "SCOM-In" = {
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "*"
      source_port_range          = "*"
      destination_port_ranges    = ["135", "137-139", "445", "5723", "49152-65535"]
      source_address_prefix      = length(var.baseline_cidrs.scom) > 0 ? null : "*"
      source_address_prefixes    = length(var.baseline_cidrs.scom) > 0 ? var.baseline_cidrs.scom : null
      destination_address_prefix = "*"
    },
    "SCOM-Out" = {
      direction                    = "Outbound"
      access                       = "Allow"
      protocol                     = "Tcp"
      source_port_range            = "*"
      destination_port_ranges      = ["5723"]
      source_address_prefix        = "*"
      destination_address_prefix   = length(var.baseline_cidrs.scom) > 0 ? null : "*"
      destination_address_prefixes = length(var.baseline_cidrs.scom) > 0 ? var.baseline_cidrs.scom : null
    }
  }
  baselines = {
    windows = merge({
      "RDP-Management-In" = {
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["3389"]
        source_address_prefix      = length(var.baseline_cidrs.management) > 0 ? null : "*"
        source_address_prefixes    = length(var.baseline_cidrs.management) > 0 ? var.baseline_cidrs.management : null
        destination_address_prefix = "*"
      },
      "KMS-Out" = {
        direction                    = "Outbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_range            = "*"
        destination_port_ranges      = ["1688"]
        source_address_prefix        = "*"
        destination_address_prefix   = length(var.baseline_cidrs.kms) > 0 ? null : "*"
        destination_address_prefixes = length(var.baseline_cidrs.kms) > 0 ? var.baseline_cidrs.kms : null
      }
    }, local.baselines_global)
    linux = merge({
      "SSH-Management-In" = {
        direction                  = "Inbound"
        access                     = "Allow"
        protocol                   = "Tcp"
        source_port_range          = "*"
        destination_port_ranges    = ["22"]
        source_address_prefix      = length(var.baseline_cidrs.management) > 0 ? null : "*"
        source_address_prefixes    = length(var.baseline_cidrs.management) > 0 ? var.baseline_cidrs.management : null
        destination_address_prefix = "*"
      },
      "Package-Repo-Out" = {
        direction                    = "Outbound"
        access                       = "Allow"
        protocol                     = "Tcp"
        source_port_range            = "*"
        destination_port_ranges      = ["80"]
        source_address_prefix        = "*"
        destination_address_prefix   = length(var.baseline_cidrs.package_repo) > 0 ? null : "*"
        destination_address_prefixes = length(var.baseline_cidrs.package_repo) > 0 ? var.baseline_cidrs.package_repo : null
      }
    }, local.baselines_global)
  }
}

# ---------------------------------------------------------
# Create NSGs
# ---------------------------------------------------------

resource "azurerm_network_security_group" "network-security-group" {
  for_each = { for k, v in var.network_security_groups : k => merge(v, { "baselines" = merge([for baseline in v.baselines : local.baselines[baseline]]...) }) }

  name                = "${var.vrf}-${var.env_name}-${var.deployment_region_friendly}-${var.descriptor}${each.key}-NSG"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  tags                = var.tags

  # ICMP - Inbound
  security_rule {
    name                       = "ICMP-In"
    priority                   = 1000
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # ICMP - Outbound
  security_rule {
    name                       = "ICMP-Out"
    priority                   = 1000
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  # DNS
  security_rule {
    name                         = "DNS-Out"
    priority                     = 1002
    direction                    = "Outbound"
    access                       = "Allow"
    protocol                     = "Udp"
    source_port_range            = "*"
    destination_port_ranges      = ["53"]
    source_address_prefix        = "*"
    destination_address_prefixes = local.use_existing_vnet ? data.azurerm_virtual_network.vnet[0].dns_servers : azurerm_virtual_network.vnet[0].dns_servers
  }

  # Baselines
  dynamic "security_rule" {
    for_each = each.value.baselines
    content {
      name                         = security_rule.key
      priority                     = index(keys(each.value.baselines), security_rule.key) + 1003 # Start from 3 to account for the 3 rules set above
      direction                    = security_rule.value.direction
      access                       = security_rule.value.access
      protocol                     = security_rule.value.protocol
      source_port_range            = can(security_rule.value.source_port_range) ? security_rule.value.source_port_range : null
      source_port_ranges           = can(security_rule.value.source_port_ranges) ? security_rule.value.source_port_ranges : null
      destination_port_range       = can(security_rule.value.destination_port_range) ? security_rule.value.destination_port_range : null
      destination_port_ranges      = can(security_rule.value.destination_port_ranges) ? security_rule.value.destination_port_ranges : null
      source_address_prefix        = can(security_rule.value.source_address_prefix) ? security_rule.value.source_address_prefix : null
      source_address_prefixes      = can(security_rule.value.source_address_prefixes) ? security_rule.value.source_address_prefixes : null
      destination_address_prefix   = can(security_rule.value.destination_address_prefix) ? security_rule.value.destination_address_prefix : null
      destination_address_prefixes = can(security_rule.value.destination_address_prefixes) ? security_rule.value.destination_address_prefixes : null
    }
  }

  # User Defined Rules
  dynamic "security_rule" {
    for_each = each.value.rules
    content {
      name                         = security_rule.key
      priority                     = security_rule.value.priority
      direction                    = security_rule.value.direction
      access                       = security_rule.value.access
      protocol                     = security_rule.value.protocol
      source_port_range            = can(security_rule.value.source_port_range) ? security_rule.value.source_port_range : null
      source_port_ranges           = can(security_rule.value.source_port_ranges) ? security_rule.value.source_port_ranges : null
      destination_port_range       = can(security_rule.value.destination_port_range) ? security_rule.value.destination_port_range : null
      destination_port_ranges      = can(security_rule.value.destination_port_ranges) ? security_rule.value.destination_port_ranges : null
      source_address_prefix        = can(security_rule.value.source_address_prefix) ? security_rule.value.source_address_prefix : null
      source_address_prefixes      = can(security_rule.value.source_address_prefixes) ? security_rule.value.source_address_prefixes : null
      destination_address_prefix   = can(security_rule.value.destination_address_prefix) ? security_rule.value.destination_address_prefix : null
      destination_address_prefixes = can(security_rule.value.destination_address_prefixes) ? security_rule.value.destination_address_prefixes : null
    }
  }
}

# ---------------------------------------------------------
# Attach NSGs - NICs
# ---------------------------------------------------------

resource "azurerm_network_interface_security_group_association" "network-security-group-attach-nic" {
  for_each = { for k, v in local.all_vms : k => v if length(v.nsg) > 0 }

  network_interface_id      = azurerm_network_interface.nic[each.key].id
  network_security_group_id = azurerm_network_security_group.network-security-group[each.value.nsg].id
}

# ---------------------------------------------------------
# Attach NSGs - Subnets
# ---------------------------------------------------------

resource "azurerm_subnet_network_security_group_association" "network-security-group-attach-subnet" {
  for_each = { for k, v in var.subnets : k => v if length(v.nsg) > 0 }

  subnet_id                 = azurerm_subnet.subnet[each.key].id
  network_security_group_id = azurerm_network_security_group.network-security-group[each.value.nsg].id
}