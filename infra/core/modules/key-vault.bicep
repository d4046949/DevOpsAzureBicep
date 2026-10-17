@description('Name of the Key Vault. Must be globally unique.')
param name string

@description('Azure region for the Key Vault.')
param location string

@description('Environment name, e.g. dev, test, prod.')
param environment string

@description('Resource tags.')
param tags object

param virtualNetworkName string

param vnid string 
@description('Number of days to retain soft-deleted items.')
@minValue(7)
@maxValue(90)
param softDeleteRetentionInDays int = 90

resource keyVaultPrivateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: 'privatelink.vaultcore.azure.net'
  location: 'global'
  tags: tags
}

resource privateDnsVnetLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: keyVaultPrivateDnsZone
  name: '${virtualNetworkName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vnid
    }
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2025-05-01' = {
  name: name
  location: location
  tags: union(tags, {
    environment: environment
  })
  properties: {
    tenantId: tenant().tenantId

    sku: {
      family: 'A'
      name: 'standard'
    }

    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: softDeleteRetentionInDays
    enablePurgeProtection: true

    publicNetworkAccess: 'Disabled'
    networkAcls: {
      bypass: 'None'
      defaultAction: 'Deny'
      ipRules: []
      virtualNetworkRules: []
    }
  }
}

@description('Name of the private endpoint subnet.')
param privateEndpointSubnetId string

@description('Name of the private endpoint.')
param privateEndpointName string = '${name}-pe'

resource keyVaultPrivateEndpoint 'Microsoft.Network/privateEndpoints@2024-05-01' = {
  name: privateEndpointName
  location: location
  tags: tags
  properties: {
    subnet: {
      id: privateEndpointSubnetId
    }
    privateLinkServiceConnections: [
      {
        name: '${name}-connection'
        properties: {
          privateLinkServiceId: keyVault.id
          groupIds: [
            'vault'
          ]
        }
      }
    ]
  }
}

resource keyVaultPrivateDnsZoneGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2024-05-01' = {
  parent: keyVaultPrivateEndpoint
  name: 'default'
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'key-vault-zone'
        properties: {
          privateDnsZoneId: keyVaultPrivateDnsZone.id
        }
      }
    ]
  }
}

output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
