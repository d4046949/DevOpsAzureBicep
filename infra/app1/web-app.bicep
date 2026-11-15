import { getRegionAbbreviation } from '../core/regions.bicep'

targetScope = 'resourceGroup'

param env string

param location string = resourceGroup().location

var region = getRegionAbbreviation(location)
var planName = 'asp-playpit-${env}-${region}'

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
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
          value: 'secret'
        }
      ]
    }
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

@description('Name of the Static Web App')
param staticWebAppName2 string = 'my-static-web-app2'

resource staticWebApp1 'Microsoft.Web/staticSites@2023-12-01' = {
  name: staticWebAppName2
  location: 'westeurope'
  sku: {
    name: 'Free'
    tier: 'Free'
  }
  properties: {}
  tags:{
    owner: 'john'
    env: 'dev'
  }
}
