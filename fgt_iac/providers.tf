provider "azurerm" {
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    virtual_machine {
      delete_os_disk_on_deletion            = true
      detach_implicit_data_disk_on_deletion = true
      graceful_shutdown                     = false
      skip_shutdown_and_force_delete        = true
    }
  }
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
}
