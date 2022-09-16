param location string = resourceGroup().location
param vmName string
param iotHubName string
param iotHubId string

var privateEndpointName = 'priv-endpoint'
var privateDnsZoneName = 'privatelink.azure-devices.net'
var pvtEndpointDnsGroupName = '${privateEndpointName}/${vmName}dnsgroup'
var iotHubPrivateIp = '10.1.3.4'
//var iotHubServiceBusPrivateIp = '10.1.3.5'
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
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'GatewaySubnet'
        properties: {
          addressPrefix: '10.1.1.0/24'
        }
      }
      {
        name: 'VMSubnet'
        properties: {
          addressPrefix: '10.1.2.0/24'
          // networkSecurityGroup: {
          //   id: nsgVm.id
          //   location: location
          // }
        }
      }
      {
        name: 'iotSubnet'
        properties: {
          addressPrefix: '10.1.3.0/24'
          // networkSecurityGroup: {
          //   id: nsgVm.id
          //   location: location
          // }
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
          nicIot.properties.ipConfigurations[0].properties.privateIPAddress
          //iotHubPrivateIp
        ]
      }
      {
        fqdn: '${iotHubNsName}.servicebus.windows.net'
        ipAddresses: [
          nicIot.properties.ipConfigurations[1].properties.privateIPAddress
          //iotHubServiceBusPrivateIp
        ]
      }
    ]
  }
}

resource privateDnsZone 'Microsoft.Network/privateDnsZones@2020-06-01' = {
  name: privateDnsZoneName
  location: 'global'
  properties: {}
  dependsOn: [
    virtualNetwork
  ]
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
        ipv4Address: virtualNetwork.properties.subnets[3].id
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

resource nicIot 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: 'nic-${iotHubName}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'nic-private-endpoint-config1-iot-private-ip'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          //privateIPAddress: iotHubPrivateIp
          subnet: {
            id: virtualNetwork.properties.subnets[3].id  // PLace on the VM Subnet
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
      {
        name: 'nic-private-endpoint-config2-iot-service-bus-private-ip'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          //privateIPAddress: iotHubServiceBusPrivateIp
          subnet: {
            id: virtualNetwork.properties.subnets[3].id  // PLace on the iot Subnet
          }
          primary: false
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}

resource nicVm 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: 'nic-${vmName}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'nic-vm'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          //privateIPAddress: iotHubPrivateIp
          subnet: {
            id: virtualNetwork.properties.subnets[2].id  // PLace on the VM Subnet
          }
          primary: true
          privateIPAddressVersion: 'IPv4'
        }
      }
    ]
  }
}

// resource privateEndpointConnectionToHub 'Microsoft.Devices/iotHubs/privateEndpointConnections@2021-07-02' = {
//   name: '${iotHubName}/${iotHubName}.${uniqueString(resourceGroup().id)}'
//   properties: {
//     privateLinkServiceConnectionState: {
//       description: 'Auto-Approved'
//       status: 'Approved'
//     }
//   }
// }

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

output subnetIdDefault string = virtualNetwork.properties.subnets[0].id
output subnetIdGateway string = virtualNetwork.properties.subnets[1].id
output subnetIdVM string = virtualNetwork.properties.subnets[2].id
output subnetIdIotHub string = virtualNetwork.properties.subnets[3].id
output vnetId string = virtualNetwork.id
output nicId string = nicVm.id
output nsgId string = nsgVm.id
