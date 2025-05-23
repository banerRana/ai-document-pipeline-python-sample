import { roleAssignmentInfo } from '../security/managed-identity.bicep'

@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@description('Name of the network interface associated with the virtual machine.')
param nicName string
@description('Subnet bound to the network interface associated with the virtual machine.')
param subnetId string
@description('Name of the public IP address for the bastion host.')
param bastionPublicIpName string
@description('Subnet bound to the bastion host.')
param bastionSubId string
@description('Computer name for the virtual machine.')
param vmComputerName string = 'aidocvm'
@description('Username for the virtual machine user.')
param vmUserName string
@description('Password for the virtual machine user.')
@secure()
param vmUserPassword string
@description('Whether to use a password or SSH key for authentication. Defaults to password.')
param authenticationType string = 'password' //'sshPublicKey'
@description('VM properties to store in Key Vault.')
param keyVaultConfig dsvmKeyVaultConfig = {
  keyVaultName: ''
  vmUserPasswordSecretName: ''
}
@description('Name of the user-assigned managed identity for the virtual machine.')
param vmManagedIdentityName string
@description('Name of the OS disk for the virtual machine.')
param vmOSDiskName string
@description('Name of the bastion host.')
param bastionName string
@description('Whether to enable Microsoft Entra ID authentication. Defaults to true.')
param enableMicrosoftEntraIdAuthentication bool = true
@description('Whether to disable copy-paste functionality in the Bastion Host resource. Defaults to true.')
param bastionDisableCopyPaste bool = true
@description('Whether to enable file copy functionality in the Bastion Host resource. Defaults to true.')
param bastionEnableFileCopy bool = true
@description('Whether to enable IP connect functionality in the Bastion Host resource. Defaults to true.')
param bastionEnableIpConnect bool = true
@description('Whether to enable shareable link functionality in the Bastion Host resource. Defaults to true.')
param bastionEnableShareableLink bool = true
@description('Whether to enable tunneling functionality in the Bastion Host resource. Defaults to true.')
param bastionEnableTunneling bool = true
@description('Role assignments to create for the App Configuration Store.')
param vmRoleAssignments roleAssignmentInfo[] = []

// Variables

@description('Map of VM sizes to VM SKUs.')
var vmSizeMap = {
  'CPU-4GB': 'Standard_B2s'
  'CPU-7GB': 'Standard_D2s_v3'
  'CPU-8GB': 'Standard_D2s_v3'
  'CPU-14GB': 'Standard_D4s_v3'
  'CPU-16GB': 'Standard_D4s_v3'
  'GPU-56GB': 'Standard_NC6_Promo'
}

var linuxConfiguration = {
  disablePasswordAuthentication: true
  ssh: {
    publicKeys: [
      {
        path: '/home/${vmUserName}/.ssh/authorized_keys'
        keyData: vmUserPassword
      }
    ]
  }
  provisionVMAgent: true
}

var contributorIdentityAssignments = [
  {
    principalId: vmManagedIdentity.properties.principalId
    roleDefinitionId: contributorRole.id
    principalType: 'ServicePrincipal'
  }
]

var keyVaultSecretsOfficerIdentityAssignments = [
  {
    principalId: vmManagedIdentity.properties.principalId
    roleDefinitionId: keyVaultSecretsOfficerRole.id
    principalType: 'ServicePrincipal'
  }
]

// Deployments

resource vmManagedIdentity 'Microsoft.ManagedIdentity/userAssignedIdentities@2025-01-31-preview' = {
  name: vmManagedIdentityName
  location: location
  tags: tags
}

resource bastionPublicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: bastionPublicIpName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
}

resource nic 'Microsoft.Network/networkInterfaces@2024-05-01' = {
  name: nicName
  location: location
  properties: {
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAddressVersion: 'IPv4'
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId
          }
        }
      }
    ]
  }
}

resource virtualMachine 'Microsoft.Compute/virtualMachines@2024-11-01' = {
  name: name
  location: location
  tags: tags
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: {
      '${vmManagedIdentity.id}': {}
    }
  }
  properties: {
    hardwareProfile: {
      vmSize: vmSizeMap['CPU-16GB']
    }
    storageProfile: {
      imageReference: {
        publisher: 'microsoft-dsvm'
        offer: 'dsvm-win-2022'
        sku: 'winserver-2022'
        version: 'latest'
      }
      osDisk: {
        name: vmOSDiskName
        createOption: 'FromImage'
      }
    }
    osProfile: {
      computerName: vmComputerName
      adminUsername: vmUserName
      adminPassword: vmUserPassword
      linuxConfiguration: ((authenticationType == 'password') ? null : linuxConfiguration)
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nic.id
        }
      ]
    }
  }
}

resource dependencyExtension 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  name: 'DependencyAgentWindows'
  parent: virtualMachine
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitoring.DependencyAgent'
    type: 'DependencyAgentWindows'
    typeHandlerVersion: '9.4'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
}

resource azureMonitorExtension 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = {
  name: 'AzureMonitorWindowsAgent'
  parent: virtualMachine
  location: location
  properties: {
    publisher: 'Microsoft.Azure.Monitor'
    type: 'AzureMonitorWindowsAgent'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: true
    enableAutomaticUpgrade: true
  }
  dependsOn: [
    dependencyExtension
  ]
}

resource entraLoginExtension 'Microsoft.Compute/virtualMachines/extensions@2024-11-01' = if (enableMicrosoftEntraIdAuthentication) {
  name: 'AADLoginForWindows'
  parent: virtualMachine
  location: location
  properties: {
    publisher: 'Microsoft.Azure.ActiveDirectory'
    type: 'AADLoginForWindows'
    typeHandlerVersion: '1.0'
    autoUpgradeMinorVersion: false
    enableAutomaticUpgrade: false
  }
  dependsOn: [
    azureMonitorExtension
  ]
}

resource vmAssignment 'Microsoft.Authorization/roleAssignments@2022-04-01' = [
  for roleAssignment in vmRoleAssignments: {
    name: guid(virtualMachine.id, roleAssignment.principalId, roleAssignment.roleDefinitionId)
    scope: virtualMachine
    properties: {
      principalId: roleAssignment.principalId
      roleDefinitionId: roleAssignment.roleDefinitionId
      principalType: roleAssignment.principalType
    }
  }
]

resource bastionHost 'Microsoft.Network/bastionHosts@2024-05-01' = {
  name: bastionName
  location: location
  sku: {
    name: 'Standard'
  }
  properties: {
    disableCopyPaste: bastionDisableCopyPaste
    enableFileCopy: bastionEnableFileCopy
    enableIpConnect: bastionEnableIpConnect
    enableShareableLink: bastionEnableShareableLink
    enableTunneling: bastionEnableTunneling
    ipConfigurations: [
      {
        name: 'ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: bastionSubId
          }
          publicIPAddress: {
            id: bastionPublicIp.id // use a public IP address for the bastion
          }
        }
      }
    ]
  }
}

resource contributorRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: resourceGroup()
  name: 'b24988ac-6180-42a0-ab88-20f7382dd24c'
}

module resourceGroupRoleAssignment '../security/resource-group-role-assignment.bicep' = {
  name: '${name}-${resourceGroup().name}-role'
  scope: resourceGroup()
  params: {
    roleAssignments: contributorIdentityAssignments
  }
}

// Using key vault to store the password.
// Not using the application key vault as it is set with no public network access for zero trust,
// but Bastion need the public network access to pull the secret from the key vault.
resource keyVault 'Microsoft.KeyVault/vaults@2024-12-01-preview' = {
  name: keyVaultConfig.keyVaultName
  location: location
  tags: tags
  properties: {
    sku: {
      name: 'standard'
      family: 'A'
    }
    tenantId: subscription().tenantId
    networkAcls: {
      defaultAction: 'Allow'
      bypass: 'AzureServices'
    }
    enabledForDeployment: true
    enabledForDiskEncryption: true
    enabledForTemplateDeployment: true
    enablePurgeProtection: true
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 90
    publicNetworkAccess: 'Enabled'
  }
}

module vmUserPasswordSecret '../security/key-vault-secret.bicep' = if (!empty(keyVaultConfig.vmUserPasswordSecretName)) {
  name: '${keyVaultConfig.vmUserPasswordSecretName}-secret'
  params: {
    keyVaultName: keyVault.name
    name: keyVaultConfig.vmUserPasswordSecretName
    value: vmUserPassword
  }
}

resource keyVaultSecretsOfficerRole 'Microsoft.Authorization/roleDefinitions@2022-05-01-preview' existing = {
  scope: keyVault
  name: 'b86a8fe4-44ce-4948-aee5-eccb2c155cd7'
}

module keyVaultRoleAssignment '../security/resource-role-assignment.json' = {
  name: '${name}-${keyVaultConfig.keyVaultName}-role'
  scope: resourceGroup()
  params: {
    resourceId: keyVault.id
    roleAssignments: keyVaultSecretsOfficerIdentityAssignments
  }
}

// Outputs

@description('ID for the deployed Virtual Machine resource.')
output id string = virtualMachine.id
@description('Name for the deployed Virtual Machine resource.')
output name string = virtualMachine.name

// Definitions

@description('Key vault secrets for the virtual machine.')
type dsvmKeyVaultConfig = {
  @description('Name of the key vault.')
  keyVaultName: string
  @description('Name of the key vault secret for the user password.')
  vmUserPasswordSecretName: string
}
