param Location string = resourceGroup().location
param adminUsername string = 'bicepadmin'
@secure()
param adminPassword string
param OSVersion string = '2019-Datacenter'

resource vm 'Microsoft.Compute/virtualMachines@2021-07-01' = {
  location: Location
  name: 'bicep-vm'
  properties: {
    hardwareProfile: {
      vmSize: 'Standard_D2s_v5'
    }
    osProfile: {
      computerName: 'bicep-vm'
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: OSVersion
        version: 'latest' 
      }
      osDisk: { 
        createOption: 'FromImage'
        managedDisk: { 
          storageAccountType: 'Standard_LRS'
        }
      }
    }
    networkProfile: {
      networkInterfaces: [
        {id: nic.id}
      ]
    }
  }
}

resource publicIP 'Microsoft.Network/publicIPAddresses@2022-05-01' = {
  name: 'bicepIP'
  location: Location
  sku: {
    name: 'Standard' 
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2022-05-01' = {
  name: 'vnetBicep'
  location: Location
  properties: {
    addressSpace: {
      addressPrefixes: [
        '192.168.0.0/16'
      ]
    }
    subnets: [
      {
        name: 'subnetBicep'
        properties: {
          addressPrefix: '192.168.1.0/24'
          networkSecurityGroup: {
            id: networkSecurityGroup.id
            }
        }
      }
    ]
  }
}

resource networkSecurityGroup 'Microsoft.Network/networkSecurityGroups@2022-05-01' = {
  name: 'nsgBicep'
  location: Location
  properties: {
    securityRules: [
      {
        name: 'allow-rdp-inbound'
        properties: {
          priority: 101
          access: 'Allow'
          direction: 'Inbound'
          destinationPortRange: '3389'
          protocol: 'Tcp' 
          sourcePortRange: '*'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
    ]
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2022-05-01' = { 
  name: 'nicBicep'
  location: Location
  properties: { 
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: { 
          privateIPAllocationMethod: 'Dynamic' 
          publicIPAddress: {
            id: publicIP.id
          }
          subnet: {
            id: resourceId('Microsoft.Network/virtualNetworks/subnets', virtualNetwork.name, virtualNetwork.properties.subnets[0].name)
          }
        }
      }
    ]
  }
  dependsOn: [
    virtualNetwork
  ]
}
