
targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment that can be used as part of naming resource convention')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

@secure()
@description('Password for the Linux VMs')
param VMPassword string

var resourceGroupName = 'rg-${environmentName}'

resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: resourceGroupName
  location: location
  tags: {
  SecurityControl: 'Ignore'
  CostControl: 'Ignore'}
}

module vnet 'modules/vnet.bicep' = {
  name: 'vnetDeployment'
  scope: resourceGroup(rg.name)
  params: {
    environmentName: environmentName
    location: location
  }
}

module nginxVM 'modules/nginx-vm.bicep' = {
  name: 'nginxVMDeployment'
  scope: resourceGroup(rg.name)
  params: {
    environmentName: environmentName
    location: location
    adminPassword: VMPassword
    adminUsername: 'adminuser'
    subnetId: vnet.outputs.subnetId
  }
}

module syslogVM 'modules/syslog-vm.bicep' = {
  name: 'syslogVMDeployment'
  scope: resourceGroup(rg.name)
  params: {
    environmentName: environmentName
    location: location
    adminPassword: VMPassword
    adminUsername: 'adminuser'
    subnetId: vnet.outputs.subnetId
  }
}
