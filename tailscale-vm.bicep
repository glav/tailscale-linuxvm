param location string = resourceGroup().location
param vmName string
param nicVmId string

@minLength(5)
param vmAdminUsername string
@secure()
param vmAdminPassword string

var storageAcctName = 'sa${uniqueString(resourceGroup().id)}'
var saAcctType = 'Standard_LRS'
var vmSize = 'Standard_D2s_v3'

//var dnsLabelPrefix = '${vmProps.name}-${uniqueString(resourceGroup().id, vmProps.name)}'

// resources


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

resource vm 'Microsoft.Compute/virtualMachines@2020-12-01' = {
  name: vmName
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
          id: nicVmId
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
        name: 'OsDisk'
        caching: 'ReadWrite'
        createOption: 'FromImage'
      }
      dataDisks: [
        {
          diskSizeGB: 100
          lun: 0
          createOption: 'Empty'
          name: 'datadisk1-${vmName}'
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

