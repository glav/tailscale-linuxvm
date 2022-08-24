param location string = resourceGroup().location
param vmName string

@minLength(5)
param vmAdminUsername string
@secure()
param vmAdminPassword string

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
