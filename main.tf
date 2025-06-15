# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-gnan-test-routing"
  location = var.location
}

# Virtual Network with 3 subnets
resource "azurerm_virtual_network" "vnet" {
  name = "vnet-ubuntu"
  # name                = "vnet-gnan-test-routing"
  address_space       = ["10.2.0.0/16"]
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

resource "azurerm_subnet" "subnet_public" {
  name                 = "subnet-public"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.2.0.0/24"]
}

resource "azurerm_subnet" "subnet_private" {
  name                 = "subnet-private"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.2.2.0/24"]
}

resource "azurerm_subnet" "subnet_nva" {
  name                 = "subnet-nva"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.2.3.0/24"]
}

# Public IP for Bastion
resource "azurerm_public_ip" "bastion_pip" {
  name                = "bastion-pip"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  allocation_method   = "Static"
  sku                 = "Standard"
}

# Azure Bastion Subnet (required name: AzureBastionSubnet)
resource "azurerm_subnet" "bastion_subnet" {
  name                 = "AzureBastionSubnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.2.1.0/24"]
}

# Azure Bastion Host
resource "azurerm_bastion_host" "bastion" {
  name                = "bastion-host"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                 = "bastion-ip-config"
    subnet_id            = azurerm_subnet.bastion_subnet.id
    public_ip_address_id = azurerm_public_ip.bastion_pip.id
  }
}

# create a Network Security Group (NSG) for the public subnet
resource "azurerm_network_security_group" "nsg_public" {
  name                = "nsg-public"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # Define a security rule to allow all outbound traffic with soruce service tag VirtualNetwork and destination service tag storage
  security_rule {
    name                       = "allow-storage-all"
    priority                   = 100
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Storage"
  }

  # Define a security rule to deny all outbound traffic with source service tag VirtualNetwork and destination service tag Internet
  security_rule {
    name                       = "deny-internet-all"
    priority                   = 110
    direction                  = "Outbound"
    access                     = "Deny"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "VirtualNetwork"
    destination_address_prefix = "Internet"
  }

}

# Associate the NSG with the public subnet
resource "azurerm_subnet_network_security_group_association" "public_subnet_nsg_assoc" {
  subnet_id                 = azurerm_subnet.subnet_public.id
  network_security_group_id = azurerm_network_security_group.nsg_public.id
}

# Network Interface for vm-nva (with IP forwarding enabled)
resource "azurerm_network_interface" "nva_nic" {
  name                = "nic-vm-nva"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  enable_ip_forwarding = true

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_nva.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Network Interface for vm-public
resource "azurerm_network_interface" "public_nic" {
  name                = "nic-vm-public"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_public.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Network Interface for vm-private
resource "azurerm_network_interface" "private_nic" {
  name                = "nic-vm-private"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  ip_configuration {
    name                          = "ipconfig1"
    subnet_id                     = azurerm_subnet.subnet_private.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Ubuntu VM vm-nva with IP forwarding enabled NIC
resource "azurerm_linux_virtual_machine" "vm_nva" {
  name                = "vm-nva"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.nva_nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub") # Adjust path to your public key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }

  # Enable IP forwarding on the VM
  custom_data = base64encode(
    <<-EOF
    #clouud-config
    # This is a placeholder for any cloud-init configuration you might want to add
    write_files:
      - path: /etc/sysctl.d/99-ip-forward.conf
        content: |
          net.ipv4.ip_forward=1
        owner: root:root
        permissions: '0644'

    runcmd:
      - sysctl -p /etc/sysctl.d/99-ip-forward.conf
    EOF
  )
}

# Ubuntu VM vm-public
resource "azurerm_linux_virtual_machine" "vm_public" {
  name                = "vm-public"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.public_nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# Ubuntu VM vm-private
resource "azurerm_linux_virtual_machine" "vm_private" {
  name                = "vm-private"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = "azureuser"

  network_interface_ids = [
    azurerm_network_interface.private_nic.id,
  ]

  admin_ssh_key {
    username   = "azureuser"
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts-gen2"
    version   = "latest"
  }
}

# Route Table for public subnet
resource "azurerm_route_table" "route_table_public" {
  name                = "route-table-public"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Route in the route table pointing to vm-nva private IP
resource "azurerm_route" "route_to_private" {
  name                   = "route-to-private-subnet"
  resource_group_name    = azurerm_resource_group.rg.name
  route_table_name       = azurerm_route_table.route_table_public.name
  address_prefix         = "10.2.2.0/24"
  next_hop_type          = "VirtualAppliance"
  next_hop_in_ip_address = azurerm_network_interface.nva_nic.ip_configuration[0].private_ip_address
}

# Associate route table to subnet-public
resource "azurerm_subnet_route_table_association" "public_subnet_route_assoc" {
  subnet_id      = azurerm_subnet.subnet_public.id
  route_table_id = azurerm_route_table.route_table_public.id
}