param location string = resourceGroup().location
param vmName string
param iotHubName string
param iotHubId string

var privateEndpointName = 'priv-endpoint'
var privateDnsZoneName = 'privatelink-${vmName}'
var pvtEndpointDnsGroupName = '${privateEndpointName}/${vmName}dnsgroup'
var iotHubPrivateIp = '10.1.0.4'
var iotHubServiceBusPrivateIp = '10.1.0.5'
var iotHubNsName = 'iothub-ns-${iotHubName}'

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'main-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.1.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'Default'
        properties: {
          addressPrefix: '10.1.0.0/24'
          networkSecurityGroup: {
            id: nsgVm.id
            location: location
          }
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'Subnet-2'
        properties: {
          addressPrefix: '10.1.1.0/24'
        }
      }
    ]
  }
}

resource privateEndpoint 'Microsoft.Network/privateEndpoints@2021-05-01' = {
  name: privateEndpointName
  location: location
  properties: {
    subnet: {
      id: virtualNetwork.properties.subnets[0].id
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
          iotHubPrivateIp
        ]
      }
      {
        fqdn: '${iotHubNsName}.servicebus.windows.net'
        ipAddresses: [
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
      id: virtualNetwork.id
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

resource nicVm 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: 'nic-${vmName}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'nic-private-endpoint-config1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddress: iotHubPrivateIp
          subnet: {
            id: virtualNetwork.properties.subnets[0].id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
      {
        name: 'nic-private-endpoint-config2'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          privateIPAddress: iotHubServiceBusPrivateIp
          subnet: {
            id: virtualNetwork.properties.subnets[0].id
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}

resource privateEndpointConnectionToHub 'Microsoft.Devices/iotHubs/privateEndpointConnections@2021-07-02' = {
  name: '${iotHubName}/${iotHubName}.${uniqueString(resourceGroup().id)}'
  properties: {
    privateLinkServiceConnectionState: {
      description: 'Auto-Approved'
      status: 'Approved'
    }
  }
}

// See https://tailscale.com/kb/1142/cloud-azure-linux/
resource nsgVm 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: '${vmName}-nsg'
  location: location
  properties: {
    securityRules: [
      {
        name: 'Tailscale UDP'
        properties: {
          description: 'UDP port 41641 for Tailscale incoming traffic'
          protocol: 'Udp'
          sourcePortRange: '*'
          destinationPortRange: '41641'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
          access: 'Allow'
          priority: 330
          direction: 'Inbound'
        }
      }
    ]
  }
}

output subnetId string = virtualNetwork.properties.subnets[0].id
output vnetId string = virtualNetwork.id
output nicId string = nicVm.id
output nsgId string = nsgVm.id
