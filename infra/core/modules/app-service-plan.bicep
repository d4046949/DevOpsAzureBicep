
@description('Name of the Key Vault. Must be globally unique.')
param name string

@description('Azure region.')
param location string

@description('Resource tags.')
param tags object

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: name
  location: location
  kind: 'linux'
  sku: {
    name: 'F1'
    tier: 'Free'
    size: 'F1'
    capacity: 1
  }
  properties: {
    reserved: true
  }
  tags: tags
}
