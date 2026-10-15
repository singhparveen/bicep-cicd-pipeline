@minLength(3)
@maxLength(24)
param storageAccountName string

@description('The location where resources will be created. Defaults to the resource group location.')
param location string = resourceGroup().location

@allowed([
  'Standard_LRS'
  'Standard_GRS'
])
param skuName string = 'Standard_LRS'

param deployBlobContainer bool = true

@description('Used to name the VNet and NSG. Keeps dev and prod resources apart.')
param environmentName string = 'dev'

@description('The network module loops over this array — one subnet per entry.')
param subnetNames array = [
  'frontend'
  'backend'
  'data'
]

var uniqueSuffix = substring(uniqueString(resourceGroup().id), 0, 8)
var storageAccountNameWithSuffix = 'st${storageAccountName}${uniqueSuffix}'

// ---------------------------------------------------------------------
// Chain 1: nsg -> network
// network takes nsg.outputs.nsgId, so Bicep deploys nsg first.
// No dependsOn written anywhere.
// ---------------------------------------------------------------------

module nsg './modules/nsg.bicep' = {
  name: 'nsgDeploy'
  params: {
    nsgName: 'nsg-${environmentName}-demo'
    location: location
  }
}

module network './modules/network.bicep' = {
  name: 'networkDeploy'
  params: {
    vnetName: 'vnet-${environmentName}-demo'
    location: location
    subnetNames: subnetNames
    nsgId: nsg.outputs.nsgId
  }
}

// ---------------------------------------------------------------------
// Chain 2: storage -> webapp
// webapp takes storage.outputs.endpoint, so storage goes first.
// Chain 1 and Chain 2 don't reference each other, so they run in parallel.
// ---------------------------------------------------------------------

module storage './modules/storage.bicep' = {
  name: 'storageDeploy'
  params: {
    storageAccountName: storageAccountNameWithSuffix
    location: location
    skuName: skuName
    deployBlobContainer: deployBlobContainer
  }
}

module webapp './modules/webapp.bicep' = {
  name: 'webAppDeploy'
  params: {
    name: 'mywebapp${uniqueSuffix}'
    location: location
    storageEndpoint: storage.outputs.endpoint
  }
}

output webAppUrl string = webapp.outputs.url
output vnetId string = network.outputs.vnetId
output subnetIds array = network.outputs.subnetIds
output storageEndpoint string = storage.outputs.endpoint
