data "azurerm_key_vault" "zimcanit_uks_mgmt_kv" {
  name                = "zimcanit-uks-mgmt-kv"
  resource_group_name = "zimcanit-dev-uks-mgmt-rg"
}

data "azurerm_key_vault_secret" "fgt_vm_uname" {
  key_vault_id = data.azurerm_key_vault.zimcanit_uks_mgmt_kv.id
  name         = "fgt-vm-uname"
}

data "azurerm_key_vault_secret" "fgt_vm_pwd" {
  key_vault_id = data.azurerm_key_vault.zimcanit_uks_mgmt_kv.id
  name         = "fgt-vm-pwd"
}
