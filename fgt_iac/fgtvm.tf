resource "azurerm_resource_group" "fgt_rg" {
  name     = "${var.resource_prefix}single-vm-rg"
  location = var.fgt_rg_location
  tags     = var.tags
}

resource "azurerm_marketplace_agreement" "fortinet_agreement" {
  publisher = var.publisher
  offer     = var.fgtoffer
  plan      = var.fgtsku[var.arch][var.license_type]
}

resource "azurerm_linux_virtual_machine" "fgtvm" {
  zone                            = "1"
  name                            = "${var.resource_prefix}vm"
  computer_name                   = "${var.resource_prefix}vm"
  allow_extension_operations      = true
  disable_password_authentication = false
  admin_username                  = data.azurerm_key_vault_secret.fgt_vm_uname.value
  admin_password                  = data.azurerm_key_vault_secret.fgt_vm_pwd.value
  location                        = azurerm_resource_group.fgt_rg.location
  resource_group_name             = azurerm_resource_group.fgt_rg.name
  priority                        = "Regular"
  provision_vm_agent              = true
  size                            = var.size
  encryption_at_host_enabled      = true
  tags                            = var.tags

  network_interface_ids = [
    azurerm_network_interface.fgt_primary_external.id, # Primary NIC
    azurerm_network_interface.fgt_private_internal.id
  ]

  source_image_reference {
    publisher = var.publisher
    offer     = var.fgtoffer
    sku       = var.fgtsku[var.arch][var.license_type]
    version   = var.fgtversion
  }

  os_disk {
    name                 = "${var.resource_prefix}osdisk"
    disk_size_gb         = 30
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  plan {
    name      = var.fgtsku[var.arch][var.license_type]
    product   = var.fgtoffer
    publisher = var.publisher
  }

  custom_data = base64encode(templatefile(
    "${path.module}/fgtvm.conf", {
      type         = var.license_type
      license_file = var.license
      format       = "${var.license_format}"
    })
  )
}

resource "azurerm_managed_disk" "fgt_vm_log_disk" {
  name                 = "${var.resource_prefix}log-disk"
  location             = azurerm_resource_group.fgt_rg.location
  resource_group_name  = azurerm_resource_group.fgt_rg.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "30"
  tags                 = var.tags
  zone                 = "1"
}

resource "azurerm_virtual_machine_data_disk_attachment" "log_disk_attach" {
  managed_disk_id    = azurerm_managed_disk.fgt_vm_log_disk.id
  virtual_machine_id = azurerm_linux_virtual_machine.fgtvm.id
  lun                = "0"
  caching            = "ReadWrite"
}

resource "azurerm_key_vault_secret" "fgt_auth_hostname" {
  name         = "fgt-single-vm-hostname"
  content_type = "Fortigate hostname used for authentication with terraform fortiOs provider: https://registry.terraform.io/providers/fortinetdev/fortios/latest/docs#configuration-for-fortigate"
  value        = azurerm_public_ip.fgt_public_ip.ip_address
  key_vault_id = data.azurerm_key_vault.zimcanit_uks_mgmt_kv.id
}
