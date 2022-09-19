param location string = resourceGroup().location
param vmName string
param hubName string
param enableIotHubPublicAccess bool = true

@minLength(5)
param vmAdminUsername string
@secure()
param vmAdminPassword string

var storageAccountName = 'saiothub${uniqueString(resourceGroup().id)}'
var storageContainerName = 'iothubresults'

module network 'private-endpoint.bicep' = {
  name: 'network-tailscale-deploy'
  params: {
    vmName: vmName
    location: location
    iotHubId: iotHub.outputs.hubId
    iotHubName: hubName
  }
}

module storage 'storage.bicep' = {
  name: 'storage-iot-hub'
  params: {
    subnetIdIotHub: network.outputs.subnetIdIotHub
    location: location
    storageAccountName: storageAccountName
    storageContainerName: storageContainerName
  }
}

module iotHub 'iot-hub.bicep' = {
  name: 'iot-hub-deploy'
  params: {
    hubName: hubName
    location: location
    enableIotHubPublicAccess: enableIotHubPublicAccess
    storageAccountName: storageAccountName
    storageContainerName: storageContainerName
  }
}

module tailVm 'tailscale-vm.bicep' = {
  name: 'tailvm-deploy'
  params: {
    vmAdminPassword: vmAdminPassword
    vmAdminUsername: vmAdminUsername
    location: location
    vmName: vmName
    nicVmId: network.outputs.nicId
  }
}
