param name string

param location string = resourceGroup().location

@description('Blob endpoint passed in from the storage module output. The web app does not know where this value comes from.')
param storageEndpoint string

@allowed([
  'F1'
  'B1'
  'S1'
])
param planSku string = 'B1'

resource appServicePlan 'Microsoft.Web/serverfarms@2024-04-01' = {
  name: 'plan-${name}'
  location: location
  sku: {
    name: planSku
  }
  kind: 'linux'
  properties: {
    reserved: true
  }
}

resource webApp 'Microsoft.Web/sites@2024-04-01' = {
  name: name
  location: location
  properties: {
    serverFarmId: appServicePlan.id
    httpsOnly: true
    siteConfig: {
      linuxFxVersion: 'NODE|22-lts'
      minTlsVersion: '1.2'
      appSettings: [
        {
          name: 'STORAGE_ENDPOINT'
          value: storageEndpoint
        }
      ]
    }
  }
}

output url string = 'https://${webApp.properties.defaultHostName}'
output id string = webApp.id
