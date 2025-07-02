
@description('Environment name for naming resources')
param environmentName string

@description('Primary location for all resources')
param location string

var vnetName = 'demo-${environmentName}-vnet'
var subnetName = 'default'
var addressPrefix = '10.0.0.0/16'
var subnetPrefix = '10.0.0.0/24'

resource vnet 'Microsoft.Network/virtualNetworks@2021-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [addressPrefix]
    }
    subnets: [
      {
        name: subnetName
        properties: {
          addressPrefix: subnetPrefix
        }
      }
    ]
  }
}

output subnetId string = vnet.properties.subnets[0].id
