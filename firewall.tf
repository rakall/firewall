variable "loc"{
    type        = string
}
resource "azurerm_resource_group" "rgfirewall" {
  name = "rgt-firewall"
  #location = azurerm_resource_group.rgmanager.locationesto está mal
  location = var.loc
}

resource "azurerm_virtual_network" "vnetfirewall" {
  name                = "vnet-firewall"
  resource_group_name = azurerm_resource_group.rgfirewall.name
  address_space       = ["172.16.0.0/16"]
  location = var.loc
}

resource "azurerm_subnet" "FrontEndSubnet"  {
    name           = "Front"
    resource_group_name  = azurerm_resource_group.rgfirewall.name
    virtual_network_name = azurerm_virtual_network.vnetfirewall.name
    address_prefixes = ["172.16.0.0/25"]
  }

resource "azurerm_subnet" "BackEndSubnet"  {
    name           = "Back"
    resource_group_name  = azurerm_resource_group.rgfirewall.name
    virtual_network_name = azurerm_virtual_network.vnetfirewall.name
    address_prefixes = ["172.16.0.128/25"]
  }

resource "azurerm_public_ip" "publicafirewall" {
    name                         = "publicafirewall"
    location                     = "westeurope"
    resource_group_name          = azurerm_resource_group.rgfirewall.name
    allocation_method = "Dynamic"
}

resource "azurerm_network_interface" "nic_firewall_back" {
    name                = "Nic_firewall_back"
    location = var.loc
    resource_group_name  = azurerm_resource_group.rgfirewall.name
    enable_ip_forwarding = "false"
	ip_configuration {
        name                          = "ip_back"
        subnet_id                     = azurerm_subnet.BackEndSubnet.id
        private_ip_address_allocation = "Static"
		private_ip_address = "172.16.0.132"
        primary = true
		public_ip_address_id = azurerm_public_ip.publicafirewall.id
    }
}
# tarjeta de red de front del Firewall
resource "azurerm_network_interface" "nic_firewall_front" {
    name                = "Nic_firewall_front"
    location = var.loc
    resource_group_name  = azurerm_resource_group.rgfirewall.name
    enable_ip_forwarding = "false"
	ip_configuration {
        name                          = "ip_front"
        subnet_id                     = azurerm_subnet.FrontEndSubnet.id
        private_ip_address_allocation = "Static"
		private_ip_address = "172.16.0.4"
        primary = true
    }
}
/*
resource "azurerm_subnet_network_security_group_association" "vinculo3" {
  subnet_id                 = azurerm_subnet.FrontEndSubnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
resource "azurerm_subnet_network_security_group_association" "vinculo2" {
  subnet_id                 = azurerm_subnet.BackEndSubnet.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}
*/
resource "azurerm_storage_account" "hdfirewall" {
    name                        = "hdfirewall"
    resource_group_name         = azurerm_resource_group.rgfirewall.name
    location                    = "westeurope"
    account_tier                = "Standard"
    account_replication_type    = "LRS"

}

resource "azurerm_virtual_machine" "firewall" {
    name                  = "firewall"
    location              = "westeurope"
    resource_group_name   = azurerm_resource_group.rgfirewall.name
    network_interface_ids = [azurerm_network_interface.nic_firewall_back.id,azurerm_network_interface.nic_firewall_front.id]
    primary_network_interface_id = azurerm_network_interface.nic_firewall_back.id
    vm_size               = "Standard_D3_v2"

    storage_os_disk {
        name              = "hdfirewall"
        caching           = "ReadWrite"
        create_option     = "FromImage"
        managed_disk_type = "Standard_LRS"
    }

    storage_image_reference {
        publisher = "checkpoint"
        offer     = "check-point-cg-r8030"
        sku       = "sg-byol"
        version   = "latest"
    }

    plan {
        name = "sg-byol"
        publisher = "checkpoint"
        product = "check-point-cg-r8030"
        }
    os_profile {
        computer_name  = "firewall"
        admin_username = "cloudmss"
        admin_password = "Password1234"
        custom_data = base64encode(data.template_file.programa.rendered)
    }

    os_profile_linux_config {
        disable_password_authentication = false
    }

    boot_diagnostics {
        enabled = "true"
        storage_uri = azurerm_storage_account.hdfirewall.primary_blob_endpoint
    }
tags ={
        x-chkp-template = "terraformfirewall"
        x-chkp-management = "tfmanager"
    }
}

data "template_file" "programa" {
  template = file("${path.module}/script.sh")
} 

output "idFrontEndSbn" {
  value = azurerm_subnet.FrontEndSubnet.id
}
output "idBackEndSbn" {
  value = azurerm_subnet.BackEndSubnet.id
}

output "rgfirewall" {
  value = azurerm_resource_group.rgfirewall.name
}

output "BackEndSubnetprefix"{
value = azurerm_subnet.BackEndSubnet.address_prefixes
}
output "FrontEndSubnetprefix"{
value = azurerm_subnet.FrontEndSubnet.address_prefixes
}

output "fwfrontprvip"{
  value= azurerm_network_interface.nic_firewall_front.private_ip_address
}
output "fwbackprvip"{
  value= azurerm_network_interface.nic_firewall_back.private_ip_address
}

output "vnetfirewall"{
  value= azurerm_virtual_network.vnetfirewall.name
}
