
@description('Environment name for naming resources')
param environmentName string

@description('Primary location for all resources')
param location string

@secure()
@description('Admin password for the VM')
param adminPassword string

@description('ID of the subnet to attach the VM to')
param subnetId string

@description('Admin username for the VM')
param adminUsername string

resource nsg 'Microsoft.Network/networkSecurityGroups@2021-05-01' = {
  name: 'nsg-${environmentName}'
  location: location
  properties: {
    securityRules: [
      {
        name: 'SSH'
        properties: {
          priority: 1000
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '22'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'ProxyPort'
        properties: {
          priority: 1010
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '8888'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource publicIp 'Microsoft.Network/publicIPAddresses@2021-05-01' = {
  name: 'nginx-pip-${environmentName}'
  location: location
  sku: {
    name: 'Basic'
  }
  properties: {
    publicIPAllocationMethod: 'Dynamic'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2021-05-01' = {
  name: 'nginx-nic-${environmentName}'
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          subnet: {
            id: subnetId
          }
          privateIPAllocationMethod: 'Dynamic'
          publicIPAddress: {
            id: publicIp.id
          }
        }
      }
    ]
    networkSecurityGroup: {
      id: nsg.id
    }
  }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  name: 'nginx-vm-${environmentName}'
  location: location
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_B1s'
    }
    osProfile: {
      computerName: 'nginx-vm'
      adminUsername: adminUsername
      adminPassword: adminPassword
      linuxConfiguration: {
        disablePasswordAuthentication: false
      }
      customData: base64('curl -s https://raw.githubusercontent.com/koenraadhaedens/azd-nignx-syslog-sentinel-ama-demo/main/infra/nginx-proxy-script.sh | bash')
    }
    storageProfile: {
      imageReference: {
        publisher: 'Canonical'
        offer: 'UbuntuServer'
        sku: '18.04-LTS'
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
      }
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

resource vmExt 'Microsoft.Compute/virtualMachines/extensions@2021-07-01' = {
  parent: vm
  name: 'nginxInstallScript'
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Extensions'
    type: 'CustomScript'
    typeHandlerVersion: '2.1'
    autoUpgradeMinorVersion: true
    settings: {
      fileUris: [
        'https://raw.githubusercontent.com/koenraadhaedens/azd-nignx-syslog-sentinel-ama-demo/main/infra/nginx-proxy-script.sh'
      ]
      commandToExecute: 'bash nginx-proxy-script.sh'
    }
  }
}
