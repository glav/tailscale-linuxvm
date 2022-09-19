param location string = resourceGroup().location
param storageAccountName string
param storageContainerName string
param subnetIdIotHub string

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
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
  kind: 'Storage'
}

resource container 'Microsoft.Storage/storageAccounts/blobServices/containers@2021-08-01' = {
  name: '${storageAccountName}/default/${storageContainerName}'
  properties: {
    publicAccess:  'None'
  }
  dependsOn: [
    storageAccount
  ]
}

output storageAccountName string = storageAccountName
output storageContainerName string = storageContainerName
