# Log Analytics Workspace & vm innsights solution and vm agents
resource "azurerm_log_analytics_workspace" "fgt_wkspace" {
  name                            = "${var.resource_prefix}wkspace"
  location                        = azurerm_resource_group.fgt_rg.location
  resource_group_name             = azurerm_resource_group.fgt_rg.name
  allow_resource_only_permissions = true
  local_authentication_disabled   = false
  internet_ingestion_enabled      = true
  internet_query_enabled          = false
  sku                             = "PerGB2018"
  retention_in_days               = 30
  identity {
    type = "SystemAssigned"
  }
  tags = var.tags
}

resource "azurerm_log_analytics_solution" "fgt_vminsights" {
  solution_name         = "VMInsights"
  location              = azurerm_resource_group.fgt_rg.location
  resource_group_name   = azurerm_resource_group.fgt_rg.name
  workspace_resource_id = azurerm_log_analytics_workspace.fgt_wkspace.id
  workspace_name        = azurerm_log_analytics_workspace.fgt_wkspace.name
  tags                  = var.tags
  plan {
    publisher = "Microsoft"
    product   = "OMSGallery/VMInsights"
  }
  depends_on = [azurerm_log_analytics_workspace.fgt_wkspace]
}

resource "azurerm_virtual_machine_extension" "fgt_dependency_agent" {
  name                       = "DAAgentExtension"
  virtual_machine_id         = azurerm_linux_virtual_machine.fgtvm.id
  publisher                  = "Microsoft.Azure.Monitoring.DependencyAgent"
  type                       = "DependencyAgentLinux"
  type_handler_version       = "9.5"
  auto_upgrade_minor_version = true
  tags                       = var.tags
  depends_on                 = [azurerm_linux_virtual_machine.fgtvm]

  lifecycle {
    ignore_changes = [tags]
  }
}

resource "azurerm_virtual_machine_extension" "fgt_ama" {
  name                       = "AMAExtension"
  virtual_machine_id         = azurerm_linux_virtual_machine.fgtvm.id
  publisher                  = "Microsoft.Azure.Monitor"
  type                       = "AzureMonitorLinuxAgent"
  type_handler_version       = "1.14"
  auto_upgrade_minor_version = "true"
  depends_on                 = [azurerm_linux_virtual_machine.fgtvm]
  tags                       = var.tags

  settings = jsonencode({
    "workspaceId" = azurerm_log_analytics_workspace.fgt_wkspace.id
  })

  protected_settings = jsonencode({
    "workspaceKey" = azurerm_log_analytics_workspace.fgt_wkspace.primary_shared_key
  })

  lifecycle {
    ignore_changes = [tags]
  }
}

# Azure Monitor DCR & association
resource "azurerm_monitor_data_collection_rule" "syslog" {
  name                = "${var.resource_prefix}syslog-dcr"
  location            = azurerm_resource_group.fgt_rg.location
  resource_group_name = azurerm_resource_group.fgt_rg.name
  tags                = var.tags
  description         = "DCR for  Linux Event Logs for system, application, and security events."
  depends_on          = [azurerm_log_analytics_workspace.fgt_wkspace]

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.fgt_wkspace.id
      name                  = "log-analytics"
    }
  }

  data_flow {
    streams      = ["Microsoft-Syslog"]
    destinations = ["log-analytics"]
  }

  data_sources {
    syslog {
      streams        = ["Microsoft-Syslog"]
      facility_names = ["syslog"]
      log_levels     = ["Debug"]
      name           = "linuxSyslogDataSource"
    }
  }
}

resource "azurerm_monitor_data_collection_rule" "vminsights" {
  name                = "${var.resource_prefix}vminsights-dcr"
  location            = azurerm_resource_group.fgt_rg.location
  resource_group_name = azurerm_resource_group.fgt_rg.name
  tags                = var.tags
  description         = "VM Insights collecting details vm metrics via counter: '\\VmInsights\\DetailedMetrics'; with a 60-second sampling frequency"
  depends_on          = [azurerm_log_analytics_workspace.fgt_wkspace]

  destinations {
    log_analytics {
      workspace_resource_id = azurerm_log_analytics_workspace.fgt_wkspace.id
      name                  = "VMInsightsPerf-Logs-Dest"
    }
  }

  data_flow {
    streams      = ["Microsoft-InsightsMetrics"]
    destinations = ["VMInsightsPerf-Logs-Dest"]
  }

  data_sources {
    performance_counter {
      streams                       = ["Microsoft-InsightsMetrics"]
      sampling_frequency_in_seconds = 60
      counter_specifiers            = ["\\VmInsights\\DetailedMetrics"]
      name                          = "VMInsightsPerfCounters"
    }
  }
}

resource "azurerm_monitor_data_collection_rule_association" "syslog" {
  name                    = "Syslog-dcr-association"
  target_resource_id      = azurerm_linux_virtual_machine.fgtvm.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.syslog.id
}

resource "azurerm_monitor_data_collection_rule_association" "vminsights" {
  name                    = "VMinsights-dcr-association"
  target_resource_id      = azurerm_linux_virtual_machine.fgtvm.id
  data_collection_rule_id = azurerm_monitor_data_collection_rule.vminsights.id
}
