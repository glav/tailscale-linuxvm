param location string = resourceGroup().location
param hubName string

resource iotHub 'Microsoft.Devices/IotHubs@2021-07-02' = {
  name: hubName
  location: location
  sku: {
    name: 'B1'
    capacity: 1
  }
  properties: {
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
  }
}

output hubHostName string = iotHub.properties.hostName
output hubId string = iotHub.id
