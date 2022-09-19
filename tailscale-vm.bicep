param location string = resourceGroup().location
param vmName string
param nicVmId string

@minLength(5)
param vmAdminUsername string
@secure()
param vmAdminPassword string
param vmStorageAccountBlobEndpoint string

var vmSize = 'Standard_D2s_v3'

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
        storageUri: vmStorageAccountBlobEndpoint
      }
    }
  }
}

