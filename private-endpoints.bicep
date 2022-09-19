param location string = resourceGroup().location
param iotHubName string
param iotHubId string
param iotHubPrivateIp string
param iotHubServiceBusPrivateIp string
param privateEndpointSubnetId string
param vNetId string

var privateDnsZoneName = 'privatelink.azure-devices.net'
var pvtEndpointDnsGroupName = '${privateEndpointName}/iotdnsgroup'
var iotHubNsName = 'iothub-ns-${iotHubName}'
var privateEndpointName = 'priv-endpoint'

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: privateEndpointSubnetId // virtualNetwork.properties.subnets[0].id 
    }
    privateLinkServiceConnections: [
      {
        name: privateEndpointName
        properties: {
          privateLinkServiceId: iotHubId
          groupIds: [
            'iotHub'
          ]
          privateLinkServiceConnectionState: {
            status: 'Approved'
            description: 'Auto-Approved'
          }
        }
      }
    ]
    customDnsConfigs: [
      {
        fqdn: '${iotHubName}.azure-devices.net'
        ipAddresses: [
          //nicIot.properties.ipConfigurations[0].properties.privateIPAddress
          iotHubPrivateIp
        ]
      }
      {
        fqdn: '${iotHubNsName}.servicebus.windows.net'
        ipAddresses: [
          //nicIot.properties.ipConfigurations[1].properties.privateIPAddress
          iotHubServiceBusPrivateIp
        ]
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  properties: {}
}

resource privateDnsZoneLink 'Microsoft.Network/privateDnsZones/virtualNetworkLinks@2020-06-01' = {
  parent: privateDnsZone
  name: '${privateDnsZoneName}-link'
  location: 'global'
  properties: {
    registrationEnabled: false
    virtualNetwork: {
      id: vNetId
    }
  }
}

resource pvtEndpointDnsGroup 'Microsoft.Network/privateEndpoints/privateDnsZoneGroups@2021-05-01' = {
  name: pvtEndpointDnsGroupName
  properties: {
    privateDnsZoneConfigs: [
      {
        name: 'config1'
        properties: {
          privateDnsZoneId: privateDnsZone.id
        }
      }
    ]
  }
  dependsOn: [
    privateEndpoint
  ]
}

resource dnsZoneAHub 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${privateDnsZone.name}/${iotHubName}'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: iotHubPrivateIp
      }
    ]  
  }
}

resource dnsZoneABus 'Microsoft.Network/privateDnsZones/A@2020-06-01' = {
  name: '${privateDnsZone.name}/${iotHubNsName}.serv'
  properties: {
    ttl: 3600
    aRecords: [
      {
        ipv4Address: iotHubServiceBusPrivateIp
      }
    ]  
  }
}

resource dnsZoneSOA 'Microsoft.Network/privateDnsZones/SOA@2018-09-01' = {
  name: '${privateDnsZone.name}/@'
  properties: {
    ttl: 3600
    soaRecord: {
      email:'azureprivatedns-host.microsoft.com'
      host: 'azureprivatedns.net'
    }
  }
}
