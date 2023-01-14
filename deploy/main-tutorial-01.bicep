@description('The Azure region into which the resources should be deployed.')
param location string = resourceGroup().location

@description('The type of environment. This must be nonprod or prod.')
@allowed([
  'nonprod'
  'prod'
])
param environmentType string

@description('A unique suffix to add to resource names that need to be globally unique.')
@maxLength(13)
param resourceNameSuffix string = uniqueString(resourceGroup().id)

var namePrefix = 'xyz-tutorial-01'
var namePrefixAlphanumeric = 'xyztut01' // all lowercase alphanumeric, max 11 chars long (max 24chars when combined with 13char resource name suffix)

var appServiceAppName = '${namePrefix}-${resourceNameSuffix}'
var appServicePlanName = '${namePrefix}-plan'
var xyzStorageAccountName = '${namePrefixAlphanumeric}${resourceNameSuffix}' // lowercase alphanumeric only, and 3-24 characters long
 
// Define the SKUs for each component based on the environment type.
var environmentConfigurationMap = {
  nonprod: {
    appServiceApp: {
      alwaysOn: false
    }
    appServicePlan: {
      sku: {
        name: 'F1'
        capacity: 1
      }
    }
    xyzStorageAccount: {
      sku: {
        name: 'Standard_LRS'
      }
    }
  }
  prod: {
    appServiceApp: {
      alwaysOn: true
    }
    appServicePlan: {
      sku: {
        name: 'S1'
        capacity: 2
      }
    }
    xyzStorageAccount: {
      sku: {
        name: 'Standard_ZRS'
      }
    }
  }
}
var xyzStorageAccountConnectionString = 'DefaultEndpointsProtocol=https;AccountName=${xyzStorageAccount.name};EndpointSuffix=${environment().suffixes.storage};AccountKey=${xyzStorageAccount.listKeys().keys[0].value}'

resource appServicePlan 'Microsoft.Web/serverFarms@2020-06-01' = {
  name: appServicePlanName
  location: location
  sku: environmentConfigurationMap[environmentType].appServicePlan.sku
}

resource appServiceApp 'Microsoft.Web/sites@2020-06-01' = {
  name: appServiceAppName
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      alwaysOn: environmentConfigurationMap[environmentType].appServiceApp.alwaysOn
      appSettings: [
        {
          name: 'XyzStorageAccountConnectionString'
          value: xyzStorageAccountConnectionString
        }
      ]
    }
  }
}

resource xyzStorageAccount 'Microsoft.Storage/storageAccounts@2021-02-01' = {
  name: xyzStorageAccountName
  location: location
  kind: 'StorageV2'
  sku: environmentConfigurationMap[environmentType].xyzStorageAccount.sku
}
