# *********************************************************
# RESOURCE GROUP
# *********************************************************

resource "azurerm_resource_group" "rg" {
  name     = "${var.vrf}-${var.env_name}-${var.deployment_region_friendly}-${var.descriptor}-RG"
  location = var.deployment_region
  tags     = var.tags
}