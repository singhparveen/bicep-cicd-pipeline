using './main.bicep'

param storageAccountName = 'prdcws'
param skuName = 'Standard_GRS'
param deployBlobContainer = true
param environmentName = 'prod'

// Prod gets a fourth subnet. Same template, different loop input —
// what-if against prod shows one extra subnet the dev deployment never had.
param subnetNames = [
  'frontend'
  'backend'
  'data'
  'management'
]
