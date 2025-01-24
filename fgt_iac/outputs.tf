output "fortigate_deployment_resource_group" {
  value = azurerm_resource_group.fgt_rg.name
}
output "fortigate_vm_deployment_region" {
  value = azurerm_resource_group.fgt_rg.location
}

output "fortigate_vm_logon_page" {
  description = "Public ip address of fortigate vm"
  value       = format("https://${azurerm_public_ip.fgt_public_ip.ip_address}")
}

output "fgt_ssh_auth" {
  value = "ssh zimcanitfgt@${azurerm_public_ip.fgt_public_ip.ip_address}"
}

output "generate_restapi_token" {
  description = "FGTcli command to generate RESTAPI token for the terraform deployment restapi. Can be ran in serial console"
  value       = "execute api-user generate-key ZimCanIT-TFM-restapi"
}

# wan interface private ip - port 1
output "wan_intf_private_ip" {
  description = "WAN interface private ip address - port 1"
  value       = azurerm_network_interface.fgt_primary_external.private_ip_address
}

# lan interface private ip - port 2
output "lan_intf_private_ip" {
  description = "LAN interface private ip address - port 2"
  value       = azurerm_network_interface.fgt_private_internal.private_ip_address
}
