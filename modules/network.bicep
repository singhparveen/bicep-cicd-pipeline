param vnetName string

param location string = resourceGroup().location

@description('One subnet is created per entry. The address prefix is calculated from the loop index.')
param subnetNames array

param addressPrefix string = '10.0.0.0/16'

@description('Resource ID of the NSG to attach to every subnet. Comes from the nsg module output, which is what makes nsg deploy before network.')
param nsgId string

resource vnet 'Microsoft.Network/virtualNetworks@2024-05-01' = {
  name: vnetName
  location: location
  properties: {
    addressSpace: {
      addressPrefixes: [
        addressPrefix
      ]
    }
    subnets: [for (name, i) in subnetNames: {
      name: name
      properties: {
        addressPrefix: '10.0.${i}.0/24'
        networkSecurityGroup: {
          id: nsgId
        }
      }
    }]
  }
}

output vnetId string = vnet.id
output vnetName string = vnet.name

// The output is looped too — one subnet ID per entry in subnetNames.
output subnetIds array = [for (name, i) in subnetNames: resourceId('Microsoft.Network/virtualNetworks/subnets', vnetName, name)]
