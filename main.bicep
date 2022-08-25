param location string = resourceGroup().location
param vmName string
param hubName string

@minLength(5)
param vmAdminUsername string
@secure()
param vmAdminPassword string

module iotHub 'iot-hub.bicep' = {
  name: 'iot-hub-deploy'
  params: {
    hubName: hubName
    location: location
  }
}
module network 'private-endpoint.bicep' = {
  name: 'network-tailscale-deploy'
  params: {
    vmName: vmName
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
  }
}
