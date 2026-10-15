using './main.bicep'

param storageAccountName = 'cws'
param skuName = 'Standard_LRS'
param deployBlobContainer = false
param environmentName = 'dev'

param subnetNames = [
  'frontend'
  'backend'
  'data'
]
