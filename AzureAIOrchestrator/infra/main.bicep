targetScope = 'subscription'

@minLength(1)
@maxLength(64)
@description('Name of the environment')
param environmentName string

@minLength(1)
@description('Primary location for all resources')
param location string

// Resource group
resource rg 'Microsoft.Resources/resourceGroups@2021-04-01' = {
  name: 'rg-${environmentName}'
  location: location
}

// App Service Plan
module appServicePlan './core/host/appserviceplan.bicep' = {
  name: 'appserviceplan'
  scope: rg
  params: {
    name: 'plan-${environmentName}'
    location: location
    sku: {
      name: 'B1'
      tier: 'Basic'
    }
  }
}

// Blazor Web App
module blazorApp './core/host/appservice.bicep' = {
  name: 'blazor-app'
  scope: rg
  params: {
    name: 'app-blazor-${environmentName}'
    location: location
    appServicePlanId: appServicePlan.outputs.id
    runtimeName: 'dotnet'
    runtimeVersion: '8.0'
    appSettings: {
      AzureComputerVision__Endpoint: 'https://eastus.api.cognitive.microsoft.com/'
    }
  }
}

// Outputs
output AZURE_RESOURCE_GROUP string = rg.name
output BLAZOR_APP_URL string = blazorApp.outputs.uri
