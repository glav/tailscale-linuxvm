param location string = resourceGroup().location
param storageAccountNameIot string
param storageContainerNameIot string
param subnetIdIotHub string
param storageAccountNameVm string
param subnetIdVm string

var saAcctType = 'Standard_LRS'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountNameIot
  location: location
  kind: 'StorageV2'
  sku: {
    name: saAcctType
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: subnetIdIotHub
          action: 'Allow'
        }
      ]
      defaultAction: 'Deny'
    }
  }
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
  name: '${storageAccountNameIot}/default/${storageContainerNameIot}'
  properties: {
    publicAccess:  'None'
  }
  dependsOn: [
    storageAccount
  ]
}

resource storageAcctVM 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAccountNameVm
  location: location
  kind: 'StorageV2'
  sku: {
    name: saAcctType
  }
  properties: {
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
    networkAcls: {
      bypass: 'AzureServices'
      virtualNetworkRules: [
        {
          id: subnetIdVm
          action: 'Allow'
        }
      ]
      defaultAction: 'Deny'
    }
  }
}

output vmStorageAccountBlobEndpoint string = storageAcctVM.properties.primaryEndpoints.blob
