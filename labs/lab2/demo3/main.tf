provider "azurerm" {
  features {}

  subscription_id = "bf30682f-317e-4047-b932-707881dc4de8"
  client_id       = "2d57d9be-4458-4caf-88ea-7153c905fd24"
  client_secret   = "8Nk7Q~vzegU3fUYc7Ggcr_Fg3LOW2tJuazQ1B"
  tenant_id       = "8f501023-d133-40bb-b595-c4be422ec157"
}

resource "azurerm_resource_group" "lab3" {
  name     = "lab3-rg"
  location = "westus"
}

resource "azurerm_storage_account" "lab3" {
  name                     = "lab3storaccdg01"
  resource_group_name      = azurerm_resource_group.lab3.name
  location                 = azurerm_resource_group.lab3.location
  account_tier             = "Standard"
  account_replication_type = "LRS"
}

resource "azurerm_storage_container" "lab3" {
  name                  = "content"
  storage_account_name  = azurerm_storage_account.lab3.name
  container_access_type = "private"
}

resource "azurerm_storage_blob" "lab3" {
  name                   = "lab3-blob-01"
  storage_account_name   = azurerm_storage_account.lab3.name
  storage_container_name = azurerm_storage_container.lab3.name
  type                   = "Block"
}

resource "azurerm_app_service_plan" "lab3" {
  name                = "lab3-appserviceplan"
  location            = azurerm_resource_group.lab3.location
  resource_group_name = azurerm_resource_group.lab3.name

  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "lab3" {
  name                = "lab3-app-service"
  location            = azurerm_resource_group.lab3.location
  resource_group_name = azurerm_resource_group.lab3.name
  app_service_plan_id = azurerm_app_service_plan.lab3.id
}

resource "azurerm_container_registry" "lab3" {
  name                = "lab3cr1"
  resource_group_name = azurerm_resource_group.lab3.name
  location            = azurerm_resource_group.lab3.location
  sku                 = "Premium"
  admin_enabled       = false
}

resource "azurerm_sql_server" "lab3" {
  name                         = "lab3sqlserverdg1"
  resource_group_name          = azurerm_resource_group.lab3.name
  location                     = "westus"
  version                      = "12.0"
  administrator_login          = "vmadmin"
  administrator_login_password = "Password@1234"
}

resource "azurerm_sql_database" "lab3" {
  name                = "mylab3sqldatabasedg1"
  resource_group_name = azurerm_resource_group.lab3.name
  location            = "westus"
  server_name         = azurerm_sql_server.lab3.name
}

resource "azurerm_kubernetes_cluster" "lab3" {
  name                = "lab3-dg1-aks"
  location            = azurerm_resource_group.lab3.location
  resource_group_name = azurerm_resource_group.lab3.name
  dns_prefix          = "lab3-dg1-k8s"

  default_node_pool {
    name            = "lab3nodepool"
    node_count      = 1
    vm_size         = "Standard_D2_v2"
    os_disk_size_gb = 30
  }

    service_principal {
    client_id       = "2d57d9be-4458-4caf-88ea-7153c905fd24"
    client_secret   = "8Nk7Q~vzegU3fUYc7Ggcr_Fg3LOW2tJuazQ1B"
  }

  role_based_access_control {
    enabled = true
  }
}
