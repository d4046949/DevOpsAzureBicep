import { getRegionAbbreviation } from '../core/regions.bicep'

targetScope = 'resourceGroup'

param env string

param location string = resourceGroup().location


param appServicePlanResourceGroup string = 'jr-playpit-core-rg'

var region = getRegionAbbreviation(location)
var planName = 'asp-playpit-${env}-${region}'
var kvName = 'kv-playpitcore04-${env}-${region}'

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' existing = {
  name: kvName
  scope: resourceGroup(appServicePlanResourceGroup)
}

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' existing = {
  name: planName
  scope: resourceGroup(appServicePlanResourceGroup)
}

param webAppName string

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  kind: 'app,linux'
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      appSettings: [
        {
          name: 'MY_SECRET'
          value: '@Microsoft.KeyVault(VaultName=${keyVault.name};SecretName=${keyVault})'
        }
      ]
    }
  }
}

module keyVaultRoleAssignment './modules/user-permissions.bicep' = {
  name: 'keyVaultRoleAssignment'
  scope: resourceGroup(appServicePlanResourceGroup)
  params: {
    keyVaultName: kvName
    principalId: webApp.identity.principalId
  }
}

@description('Name of the Static Web App')
param staticWebAppName string = 'my-static-web-app'

resource staticWebApp 'Microsoft.Web/staticSites@2023-12-01' = {
  name: staticWebAppName
  location: 'westeurope'
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {}
}
