import { getRegionAbbreviation } from './regions.bicep'

targetScope = 'resourceGroup'

@description('Owner tag value')
param owner string

var tags = {
  owner: owner
  env: env
}

@description('Resource location, defaults to the resource group')
param location string = resourceGroup().location

@description('Environment name')
@allowed([
'dev'
'test'
'staging'
])
param env string

var region = getRegionAbbreviation(location)

var kvName = 'kv-playpitcore-${env}-${region}'
var planName = 'asp-playpit-${env}-${region}'

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: kvName
  location: location
  properties: {
    tenantId: tenant().tenantId
    sku: {
      family: 'A'
      name: 'standard'
    }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90

    publicNetworkAccess: 'Enabled'
    networkAcls: {
      bypass: 'None'
    }
    accessPolicies: []
  }
  tags: tags
}

// App Service Plan - Basic B1 Linux
resource appServicePlan 'Microsoft.Web/serverfarms@2023-12-01' = {
  name: planName
  location: location
  kind: 'linux'
  sku: {
    name: 'B1'
    tier: 'Basic'
    size: 'B1'
    capacity: 1
  }
  properties: {
    reserved: true
  }
  tags: tags
}
