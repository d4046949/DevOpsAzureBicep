targetScope = 'resourceGroup'

@description('Name of the Static Web App')
param staticWebAppName string

resource staticWebApp 'Microsoft.Web/staticSites@2023-12-01' = {
  name: staticWebAppName
  location: 'westeurope'
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {}
  tags: {
  owner: 'john'
  }
}
