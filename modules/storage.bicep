param storageAccountName string
param location string = resourceGroup().location
param skuName string = 'Standard_LRS'
param deployBlobContainer bool = true

resource storageAccount 'Microsoft.Storage/storageAccounts@2025-08-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: {name: skuName}
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2025-08-01' = if (deployBlobContainer) {
  name: '${storageAccount.name}/default/mycontainer'
}

output id string = storageAccount.id
output endpoint string = storageAccount.properties.primaryEndpoints.blob
