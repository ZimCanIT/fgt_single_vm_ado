# Fortigate VNET
resource "azurerm_virtual_network" "fgt_vnet" {
  name                = "${var.resource_prefix}vnet"
  address_space       = [var.vnetcidr]
  location            = azurerm_resource_group.fgt_rg.location
  resource_group_name = azurerm_resource_group.fgt_rg.name
  tags                = var.tags
}

resource "azurerm_subnet" "fgt_public_subnet" {
  name                 = "${var.resource_prefix}public-snet"
  resource_group_name  = azurerm_resource_group.fgt_rg.name
  virtual_network_name = azurerm_virtual_network.fgt_vnet.name
  address_prefixes     = [var.publiccidr]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_subnet" "fgt_private_subnet" {
  name                 = "${var.resource_prefix}private-snet"
  resource_group_name  = azurerm_resource_group.fgt_rg.name
  virtual_network_name = azurerm_virtual_network.fgt_vnet.name
  address_prefixes     = [var.privatecidr]
  service_endpoints    = ["Microsoft.Storage"]
}

resource "azurerm_public_ip" "fgt_public_ip" {
  name                = "${var.resource_prefix}pip"
  location            = azurerm_resource_group.fgt_rg.location
  resource_group_name = azurerm_resource_group.fgt_rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
  lifecycle {
    prevent_destroy = true # prevent accidental deletion
  }
}

resource "azurerm_management_lock" "fgt_pip_lock" {
  name       = "${var.resource_prefix}pip-LOCK"
  scope      = azurerm_public_ip.fgt_public_ip.id
  lock_level = "ReadOnly"
  notes      = "This FortiGate external public IP is Read-Only, and cannot be deleted."
}

resource "azurerm_network_interface" "fgt_primary_external" {
  name                           = "${var.resource_prefix}external-nic"
  location                       = azurerm_resource_group.fgt_rg.location
  resource_group_name            = azurerm_resource_group.fgt_rg.name
  ip_forwarding_enabled          = true # Enable IP forwarding - required for NAT
  accelerated_networking_enabled = true
  tags                           = var.tags

  ip_configuration {
    name                          = "${var.resource_prefix}external"
    subnet_id                     = azurerm_subnet.fgt_public_subnet.id
    private_ip_address_allocation = var.nic_ip_allocation
    private_ip_address            = var.external_nic_private_ipv4
    primary                       = true
    public_ip_address_id          = azurerm_public_ip.fgt_public_ip.id
  }
}

resource "azurerm_network_interface" "fgt_private_internal" {
  name                           = "${var.resource_prefix}internal-nic"
  location                       = azurerm_resource_group.fgt_rg.location
  resource_group_name            = azurerm_resource_group.fgt_rg.name
  ip_forwarding_enabled          = false
  accelerated_networking_enabled = false
  tags                           = var.tags

  ip_configuration {
    name                          = "${var.resource_prefix}internal"
    subnet_id                     = azurerm_subnet.fgt_private_subnet.id
    private_ip_address_allocation = var.nic_ip_allocation
    private_ip_address            = var.internal_nic_private_ipv4
  }
}

# Internal route table and route
resource "azurerm_route_table" "internal_rt" {
  depends_on          = [azurerm_linux_virtual_machine.fgtvm]
  name                = "${var.resource_prefix}internal-rt"
  location            = azurerm_resource_group.fgt_rg.location
  resource_group_name = azurerm_resource_group.fgt_rg.name
}

resource "azurerm_route" "default_fgt_route" {
  name                   = "${var.resource_prefix}route"
  resource_group_name    = azurerm_resource_group.fgt_rg.name
  route_table_name       = azurerm_route_table.internal_rt.name
  address_prefix         = "0.0.0.0/0"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.fgt_private_internal.private_ip_address
}

resource "azurerm_subnet_route_table_association" "internalassociate" {
  depends_on     = [azurerm_route_table.internal_rt]
  subnet_id      = azurerm_subnet.fgt_private_subnet.id
  route_table_id = azurerm_route_table.internal_rt.id
}
