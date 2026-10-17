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

    publicNetworkAccess: 'Enabled'

  }
}

output keyVaultId string = keyVault.id
output keyVaultName string = keyVault.name
output keyVaultUri string = keyVault.properties.vaultUri
