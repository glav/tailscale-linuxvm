param location string = resourceGroup().location
param vmName string
param hubName string
param enableIotHubPublicAccess bool = true

@minLength(5)
param vmAdminUsername string
@secure()
param vmAdminPassword string

// Common storage account names
var storageAccountNameIot = 'saiothub${uniqueString(resourceGroup().id)}'
var storageContainerNameIot = 'iothubresults'
var storageAcctNameVm = 'savm${uniqueString(resourceGroup().id)}'

module network 'networking.bicep' = {
  name: 'network-tailscale-deploy'
  params: {
    location: location
  }
}

module storage 'storage.bicep' = {
  name: 'storage-iot-hub'
  params: {
    subnetIdIotHub: network.outputs.subnetIdIotHub
    location: location
    storageAccountNameIot: storageAccountNameIot
    storageContainerNameIot: storageContainerNameIot
    storageAccountNameVm: storageAcctNameVm
    subnetIdVm: network.outputs.subnetIdVM
  }
}

module iotHub 'iot-hub.bicep' = {
  name: 'iot-hub-deploy'
  params: {
    hubName: hubName
    location: location
    enableIotHubPublicAccess: enableIotHubPublicAccess
    storageAccountName: storageAccountNameIot
    storageContainerName: storageContainerNameIot
  }
}

module privateEndpoints 'private-endpoints.bicep' = {
  name: 'private-endpoints-deploy'
  params: {
    iotHubId: iotHub.outputs.hubId
    iotHubName: hubName
    iotHubPrivateIp: network.outputs.nicIotHubPrivateIp
    iotHubServiceBusPrivateIp: network.outputs.nicIotSvcBusPrivateIp
    privateEndpointSubnetId: network.outputs.subnetIdDefault
    vNetId: network.outputs.vnetId
    location: location
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
    vmStorageAccountBlobEndpoint: storage.outputs.vmStorageAccountBlobEndpoint
  }
}
