param location string = resourceGroup().location
param vmName string

@minLength(5)
param vmAdminUsername string
@secure()
param vmAdminPassword string


module tailVm 'tailscale-vm.bicep' = {
  name: 'tailvm-deploy'
  params: {
    vmAdminPassword: vmAdminPassword
    vmAdminUsername: vmAdminUsername
    location: location
    vmName: vmName
  }
}
