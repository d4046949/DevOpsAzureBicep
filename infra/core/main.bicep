import { getRegionAbbreviation } from './regions.bicep'

targetScope = 'resourceGroup'

@description('Owner tag value')
param owner string

var tags = {
  owner: owner
  env: env
}

param vnetAddress string = '10.0.0.0/16'
param subnet1 string
param subnet2 string

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

var kvName = 'kv-playpitcore04-${env}-${region}'
var planName = 'asp-playpit-${env}-${region}'
var virtualNetworkName string = 'vnet-playpit-${env}-01'

@description('App Service integration subnet name')
param integrationSubnetName string = 'snet-app-integration'

@description('Private Endpoint subnet name')
param privateEndpointSubnetName string = 'snet-private-endpoints'

module keyVault './modules/key-vault.bicep' = {
  params: {
    name: kvName
    location: location
    environment: env
    tags:tags
    virtualNetworkName: virtualNetwork.name
    vnid: virtualNetwork.id
    privateEndpointSubnetId: resourceId(
  'Microsoft.Network/virtualNetworks/subnets',
  virtualNetworkName,
  privateEndpointSubnetName
) 
    privateEndpointName: 'pe-${kvName}'
  }
}


module appServicePlan './modules/app-service-plan.bicep' = {
  params: {
    name: planName
    location: location
    tags:tags
  }
}

// NSG for application integration
resource appIntegrationNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-app-integration-dev'
  location: location
  properties: {
    securityRules: []
  }
}

// NSG for private endpoints
resource privateEndpointsNsg 'Microsoft.Network/networkSecurityGroups@2023-09-01' = {
  name: 'nsg-private-endpoints-dev'
  location: location
  properties: {
    securityRules: []
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2023-11-01' = {
  name: virtualNetworkName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        vnetAddress
      ]
    }
    subnets: [
      {
        name: integrationSubnetName
        properties: {
          addressPrefix: subnet1
          networkSecurityGroup: {
      id: appIntegrationNsg.id
    }
          delegations: [
            {
              name: 'appServiceDelegation'
              properties: {
                serviceName: 'Microsoft.Web/serverFarms'
              }
            }
          ]
        }
      }
      {
        name: privateEndpointSubnetName
        properties: {
          addressPrefix: subnet2    
          networkSecurityGroup: {
      id: privateEndpointsNsg.id
    }
        }
      }
    ]
  }
  tags: tags
}


