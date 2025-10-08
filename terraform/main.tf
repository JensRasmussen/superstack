# Terraform configuration for Azure AKS
provider "azurerm" {
  features {}
}

resource "azurerm_resource_group" "aks_rg" {
  name     = "aks-resource-group"
  location = "East US"  # Cheapest Azure region
}

resource "azurerm_kubernetes_cluster" "aks" {
  name                = "aks-cluster"
  location            = azurerm_resource_group.aks_rg.location
  resource_group_name = azurerm_resource_group.aks_rg.name
  dns_prefix          = "aksdns"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_B2s"  # Cheapest burstable VM (2 vCPU, 4GB RAM)
  }

  identity {
    type = "SystemAssigned"
  }

  kubernetes_version = "1.28.3"

  sku_tier = "Free"  # Free tier (vs Standard/Premium)
}

# Azure Container Registry for images
resource "azurerm_container_registry" "acr" {
  name                = "superstackacr${random_integer.rand.result}"
  resource_group_name = azurerm_resource_group.aks_rg.name
  location            = azurerm_resource_group.aks_rg.location
  sku                 = "Basic"
  admin_enabled       = false
}

resource "random_integer" "rand" {
  min = 10000
  max = 99999
}

# Grant AKS pull access to ACR
resource "azurerm_role_assignment" "aks_acr_pull" {
  scope                = azurerm_container_registry.acr.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_kubernetes_cluster.aks.kubelet_identity[0].object_id
}

output "acr_name" {
  value = azurerm_container_registry.acr.name
}

output "resource_group_name" {
  value = azurerm_resource_group.aks_rg.name
}

output "aks_name" {
  value = azurerm_kubernetes_cluster.aks.name
}
