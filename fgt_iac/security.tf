#  Network Security Groups public/private
resource "azurerm_network_security_group" "pub" {
  name                = "${var.resource_prefix}pub-nsg"
  location            = azurerm_resource_group.fgt_rg.location
  resource_group_name = azurerm_resource_group.fgt_rg.name
  tags                = var.tags

  security_rule {
    name                       = "ALLOW-inbound-all"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "ALLOW-outbound-all"
    priority                   = 101
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}

resource "azurerm_network_security_group" "priv" {
  name                = "${var.resource_prefix}priv-nsg"
  location            = azurerm_resource_group.fgt_rg.location
  resource_group_name = azurerm_resource_group.fgt_rg.name
  tags                = var.tags

  security_rule {
    name                       = "ALLOW-inbound-all"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
  security_rule {
    name                       = "ALLOW-outbound-all"
    priority                   = 101
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}


resource "azurerm_network_interface_security_group_association" "public" {
  depends_on                = [azurerm_network_interface.fgt_primary_external]
  network_interface_id      = azurerm_network_interface.fgt_primary_external.id
  network_security_group_id = azurerm_network_security_group.pub.id
}

resource "azurerm_network_interface_security_group_association" "private" {
  depends_on                = [azurerm_network_interface.fgt_private_internal]
  network_interface_id      = azurerm_network_interface.fgt_private_internal.id
  network_security_group_id = azurerm_network_security_group.priv.id
}
