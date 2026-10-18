import { getRegionAbbreviation } from '../core/regions.bicep'

targetScope = 'resourceGroup'

param env string

param location string = resourceGroup().location


param appServicePlanResourceGroup string = ''

var region = getRegionAbbreviation(location)
var planName = 'asp-playpit-${env}-${region}'

resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' existing = {
  name: planName
  scope: resourceGroup(appServicePlanResourceGroup)
}

param webAppName string

resource webApp 'Microsoft.Web/sites@2023-12-01' = {
  name: webAppName
  location: location
  kind: 'app,linux'
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
  }
}
