@description('Name of the existing Container App resource.')
param name string

// Deployments

resource containerApp 'Microsoft.App/containerApps@2025-01-01' existing = {
  name: name
}

// Outputs

@description('List of containers defined in the template for the existing Container App resource.')
output containers array = containerApp.properties.template.containers
