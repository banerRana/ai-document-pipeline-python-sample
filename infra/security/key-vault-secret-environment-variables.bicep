@description('URI for the Key Vault associated with the environment variables.')
param keyVaultSecretUri string
@description('Names of the environment variables to retrieve from Key Vault Secrets.')
param variableNames array

// Variables

var keyVaultSettings = [
  for setting in variableNames: {
    name: setting
    value: '@Microsoft.KeyVault(SecretUri=${keyVaultSecretUri}secrets/${setting})'
  }
]

// Outputs

@description('Environment variables containing the name and a value represented as a Key Vault Secret URI.')
output environmentVariables environmentVariableInfo[] = keyVaultSettings

// Definitions

@export()
@description('Information about the environment variables containing the name and a value represented as a Key Vault Secret URI.')
type environmentVariableInfo = {
  name: string
  value: string
}
