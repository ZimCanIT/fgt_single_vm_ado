locals {
  network_watcher_tags = {
    Application     = "Network Watcher"
    Criticality     = "Tier 1"
    Owner           = "ZimCanIT"
    Environment     = "Dev"
    Deployment      = "Terraform via Az-DevOps CI/CD"
    ReleasePipeline = "Deploy-ZimCanIT-UKS-Single-Fortigate"
  }
}

resource "azurerm_resource_group" "uksouth" {
  name     = var.ntwk_watcher_rg_name
  location = var.ntwk_watcher_rg_location
  tags     = local.network_watcher_tags
}

resource "azurerm_network_watcher" "uksouth" {
  name                = "NetworkWatcher_uksouth"
  location            = azurerm_resource_group.uksouth.location
  resource_group_name = azurerm_resource_group.uksouth.name
  tags                = local.network_watcher_tags
}
