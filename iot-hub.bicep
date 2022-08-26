param location string = resourceGroup().location
param hubName string

var storageAccountName = 'saiothub${uniqueString(resourceGroup().id)}'
var storageContainerName = 'iothubresults'
var storageEndpoint = 'iotStorageEndpont'

resource storageAccount 'Microsoft.Storage/storageAccounts@2021-08-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource iotHub 'Microsoft.Devices/IotHubs@2021-07-02' = {
  name: hubName
  location: location
  sku: {
    name: 'F1'
    capacity: 1
  }
  identity: {
    type: 'SystemAssigned'
  }
  properties: {
    features: 'DeviceManagement'
    disableLocalAuth: false
    publicNetworkAccess: 'Disabled'
    privateEndpointConnections: [
      {
        properties: {
          privateLinkServiceConnectionState: {
            description: 'Auto-Approved'
            status: 'Approved'
          }
        }
      }
    ]
    routing: {
      endpoints: {
        storageContainers: [
          {
            connectionString: 'DefaultEndpointsProtocol=https;AccountName=${storageAccountName};EndpointSuffix=${environment().suffixes.storage};AccountKey=${storageAccount.listKeys().keys[0].value}'
            containerName: storageContainerName
            fileNameFormat: '{iothub}/{partition}/{YYYY}/{MM}/{DD}/{HH}/{mm}'
            batchFrequencyInSeconds: 100
            maxChunkSizeInBytes: 104857600
            encoding: 'JSON'
            name: storageEndpoint
          }
        ]
      }
      routes: [
        {
          name: 'ContosoStorageRoute'
          source: 'DeviceMessages'
          condition: 'level="storage"'
          endpointNames: [
            storageEndpoint
          ]
          isEnabled: true
        }
      ]
    }
  }
}

output hubHostName string = iotHub.properties.hostName
output hubId string = iotHub.id
