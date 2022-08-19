param location string = resourceGroup().location
param vmName string

@minLength(5)
param vmAdminUsername string
@secure()
param vmAdminPassword string

// Locals
var vmProps = {
    name: vmName
    privateIPAllocationMethod: 'Dynamic'
}

var storageAcctName = 'sa${uniqueString(resourceGroup().id)}'
var saAcctType = 'Standard_LRS'
var vmSize = 'Standard_D2s_v3'

var dnsLabelPrefix = '${vmProps.name}-${uniqueString(resourceGroup().id, vmProps.name)}'

// resources

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2019-11-01' = {
  name: 'main-vnet'
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '10.0.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'Subnet-1'
        properties: {
          addressPrefix: '10.0.0.0/24'
          networkSecurityGroup: {
            id: nsgVm.id
            location: location
          }
        }
      }
      {
        name: 'Subnet-2'
        properties: {
          addressPrefix: '10.0.1.0/24'
        }
      }
    ]
  }
}


resource nicvm 'Microsoft.Network/networkInterfaces@2020-05-01' = {
  name: 'nic-${vmProps.name}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'nic-config1'
        properties: {
          privateIPAllocationMethod: vmProps.privateIPAllocationMethod
          subnet: {
            id: virtualNetwork.properties.subnets[0].id
          }
        }
      }
    ]
  }
}

resource storageAcct 'Microsoft.Storage/storageAccounts@2019-06-01' = {
  name: storageAcctName
  location: location
  kind: 'StorageV2'
  sku: {
    name: saAcctType
  }
  properties: {
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
    minimumTlsVersion: 'TLS1_2'
  }
}

// See https://tailscale.com/kb/1142/cloud-azure-linux/
resource nsgVm 'Microsoft.Network/networkSecurityGroups@2019-11-01' = {
  name: 'name'
  location: location
  properties: {
    securityRules: [
      {
        name: '${vmName}-nsg'
        properties: {
          description: 'NSG for ${vmName}'
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

resource vm 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmProps.name
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: vmAdminUsername
      adminPassword: vmAdminPassword
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicvm.id
          properties: {
            primary: true
          }
        }
      ]
    }
    storageProfile: {
      imageReference: {
        publisher: 'canonical'
        offer: '0001-com-ubuntu-server-focal'
        sku: '20_04-lts-gen2'
        version: 'latest'
}
      osDisk: {
        name: 'name'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          diskSizeGB: 100
          lun: 0
          createOption: 'Empty'
          name: 'datadisk1-${vmProps.name}'
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAcct.properties.primaryEndpoints.blob
      }
    }
  }
}

output subnetId string = virtualNetwork.properties.subnets[0].id
output vnetId string = virtualNetwork.id
