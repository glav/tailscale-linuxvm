param location string = resourceGroup().location

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
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
        }
      }
      {
        name: 'VMSubnet'
        properties: {
          addressPrefix: '10.1.2.0/24'
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
              locations: [
                'AustraliaEast'
                'AustraliaSouthEast'
              ]
            }
          ]
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
          privateEndpointNetworkPolicies: 'Disabled'
          privateLinkServiceNetworkPolicies: 'Enabled'
          serviceEndpoints: [
            {
              service: 'Microsoft.Storage'
              locations: [
                'AustraliaEast'
                'AustraliaSouthEast'
              ]
            }
          ]
          // networkSecurityGroup: {
          //   id: nsgVm.id
          //   location: location
          // }
        }
      }
    ]
  }
}


resource nicIot 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: 'nic-iot-hub'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'nic-private-endpoint-config1-iot-private-ip'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          //privateIPAddress: iotHubPrivateIp
          subnet: {
            id: virtualNetwork.properties.subnets[3].id  // PLace on the iot Subnet
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
  name: 'nic-virtual-machine-gateway'
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

// See https://tailscale.com/kb/1142/cloud-azure-linux/
resource nsgVm 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'nsg-main'
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
output nicIotHubPrivateIp string = nicIot.properties.ipConfigurations[0].properties.privateIPAddress
output nicIotSvcBusPrivateIp string = nicIot.properties.ipConfigurations[1].properties.privateIPAddress
