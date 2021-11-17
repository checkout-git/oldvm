provider "azurerm" {
  features {}

  subscription_id = "bf30682f-317e-4047-b932-707881dc4de8"
  client_id       = "2d57d9be-4458-4caf-88ea-7153c905fd24"
  client_secret   = "8Nk7Q~vzegU3fUYc7Ggcr_Fg3LOW2tJuazQ1B"
  tenant_id       = "8f501023-d133-40bb-b595-c4be422ec157"
}

# Create a resource group  

resource "azurerm_resource_group" "rg_lab1" {
  name     = "${var.resource_prefix}-RG"
  location = var.node_location
}

# Create a virtual network within the resource group
resource "azurerm_virtual_network" "lab1_vm_vnet" {
  name                = "${var.resource_prefix}-vnet"
  resource_group_name = azurerm_resource_group.rg_lab1.name
  location            = var.node_location
  address_space       = var.node_address_space
}
# Create a subnets within the virtual network
resource "azurerm_subnet" "lab1_vm_subnet" {
  name                 = "${var.resource_prefix}-subnet"
  resource_group_name  = azurerm_resource_group.rg_lab1.name
  virtual_network_name = azurerm_virtual_network.lab1_vm_vnet.name
  address_prefix       = var.node_address_prefix
}
# Create Linux Public IP
resource "azurerm_public_ip" "lab1_vm_public_ip" {
  count = var.node_count
  name  = "${var.resource_prefix}-${format("%02d", count.index)}-PublicIP"
  #name = "${var.resource_prefix}-PublicIP"
  location            = azurerm_resource_group.rg_lab1.location
  resource_group_name = azurerm_resource_group.rg_lab1.name
  allocation_method   = "Static"

}
# Create Network Interface
resource "azurerm_network_interface" "lab1_vm_nic" {
  count = var.node_count
  #name = "${var.resource_prefix}-NIC"
  name                = "${var.resource_prefix}-${format("%02d", count.index)}-NIC"
  location            = azurerm_resource_group.rg_lab1.location
  resource_group_name = azurerm_resource_group.rg_lab1.name
  #

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lab1_vm_subnet.id
    private_ip_address_allocation = "Dynamic"
    public_ip_address_id          = element(azurerm_public_ip.lab1_vm_public_ip.*.id, count.index)
    #public_ip_address_id = azurerm_public_ip.lab1_vm_public_ip.id
    #public_ip_address_id = azurerm_public_ip.lab1_vm_public_ip.id
  }
}
# Creating resource NSG
resource "azurerm_network_security_group" "lab1_vm_nsg" {
  name                = "${var.resource_prefix}-NSG"
  location            = azurerm_resource_group.rg_lab1.location
  resource_group_name = azurerm_resource_group.rg_lab1.name
  # Security rule can also be defined with resource azurerm_network_security_rule, here just defining it inline.

  security_rule {
    name                       = "Inbound"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }
}
# Subnet and NSG association
resource "azurerm_subnet_network_security_group_association" "lab1_vm_subnet_nsg_association" {
  subnet_id                 = azurerm_subnet.lab1_vm_subnet.id
  network_security_group_id = azurerm_network_security_group.lab1_vm_nsg.id
}
# Virtual Machine Creation — Linux
resource "azurerm_virtual_machine" "lab1_vm_linux_vm" {
  count = var.node_count
  name  = "${var.resource_prefix}-${format("%02d", count.index)}"
  #name = "${var.resource_prefix}-${count.index}"
  #name = "${var.resource_prefix}-VM"
  location                      = azurerm_resource_group.rg_lab1.location
  resource_group_name           = azurerm_resource_group.rg_lab1.name
  network_interface_ids         = [element(azurerm_network_interface.lab1_vm_nic.*.id, count.index)]
  vm_size                       = "Standard_A1_v2"
  delete_os_disk_on_termination = true

  storage_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "18.04-LTS"
    version   = "latest"
  }

  storage_os_disk {
    name              = "myosdisk-${count.index}"
    caching           = "ReadWrite"
    create_option     = "FromImage"
    managed_disk_type = "Standard_LRS"
  }

  os_profile {
    computer_name  = "linuxhost"
    admin_username = "vmadmin"
    admin_password = "Password@1234"
  }

  os_profile_linux_config {
    disable_password_authentication = false
  }
}

resource "null_resource" "r0" {
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt install openjdk-11-jre-headless -y",
      "sudo apt install maven -y",
      "sudo apt-get install tree -y",
      "sudo curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash",
      "sudo mkdir /home/vmadmin/jenkins",
      "sudo wget https://get.jenkins.io/war-stable/2.303.1/jenkins.war",
      "sudo chown vmadmin:vmadmin jenkins",
      "sudo chown vmadmin:vmadmin jenkins.war",
      "sudo mv /home/vmadmin/jenkins.war /home/vmadmin/jenkins",
      "sudo apt-get update"
    ]

    connection {
      type     = "ssh"
      host     = element(azurerm_public_ip.lab1_vm_public_ip.*.ip_address, 0)
      user     = "vmadmin"
      password = "Password@1234"
    }
  }
}

resource "null_resource" "r1" {
  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install docker.* -y",
      "sudo apt install openjdk-11-jre-headless -y",
      "sudo apt install maven -y",
      "sudo apt-get update",
      "sudo apt-get install software-properties-common",
      "sudo apt-add-repository ppa:ansible/ansible",
      "sudo apt install ansible -y",
      "sudo apt-get install -y python-pip",
      "sudo apt-get install tree -y",
      "sudo apt-get install nginx -y",
      "sudo curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash",
      "sudo apt-get update",
      "sudo chown vmadmin:vmadmin /etc/ansible"
    ]

    connection {
      type     = "ssh"
      host     = element(azurerm_public_ip.lab1_vm_public_ip.*.ip_address, 1)
      user     = "vmadmin"
      password = "Password@1234"
    }
  }
}