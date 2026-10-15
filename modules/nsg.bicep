param nsgName string

param location string = resourceGroup().location

resource nsg 'Microsoft.Network/networkSecurityGroups@2024-05-01' = {
  name: nsgName
  location: location
  properties: {
    securityRules: [
      {
        name: 'AllowHTTP'
        properties: {
          priority: 100
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '80'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      {
        name: 'AllowHTTPS'
        properties: {
          priority: 110
          direction: 'Inbound'
          access: 'Allow'
          protocol: 'Tcp'
          sourcePortRange: '*'
          destinationPortRange: '443'
          sourceAddressPrefix: '*'
          destinationAddressPrefix: '*'
        }
      }
      // ---------------------------------------------------------------
      // What-if exercise: uncomment this rule and run what-if again.
      // The NSG shows as Modify, with AllowSSH as the only addition.
      // Don't deploy it as-is: it opens SSH to the whole internet.
      // ---------------------------------------------------------------
      // {
      //   name: 'AllowSSH'
      //   properties: {
      //     priority: 120
      //     direction: 'Inbound'
      //     access: 'Allow'
      //     protocol: 'Tcp'
      //     sourcePortRange: '*'
      //     destinationPortRange: '22'
      //     sourceAddressPrefix: '*'
      //     destinationAddressPrefix: '*'
      //   }
      // }
    ]
  }
}

output nsgId string = nsg.id
output nsgName string = nsg.name
