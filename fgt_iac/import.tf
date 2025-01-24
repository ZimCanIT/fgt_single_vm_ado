# imoport block required for terraform runs post initial-apply 
import {
  to = azurerm_marketplace_agreement.fortinet_agreement
  # https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/functions/normalise_resource_id
  id = provider::azurerm::normalise_resource_id("/subscriptions/${var.subscription_id}/providers/Microsoft.MarketplaceOrdering/agreements/fortinet/offers/fortinet_fortigate-vm_v5/plans/fortinet_fg-vm_payg_2023_g2")
}

# FortiGate VM resource group
import {
  to = azurerm_resource_group.fgt_rg
  id = provider::azurerm::normalise_resource_id("/subscriptions/${var.subscription_id}/resourceGroups/zimcanit_single_fgt_vm_rg")
}

# FortiGate public IP 
import {
  to = azurerm_public_ip.fgt_public_ip
  id = provider::azurerm::normalise_resource_id("/subscriptions/${var.subscription_id}/resourceGroups/zimcanit_single_fgt_vm_rg/providers/Microsoft.Network/publicIPAddresses/fgt-public-ip")
}
