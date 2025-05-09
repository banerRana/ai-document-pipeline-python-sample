@description('Name of the resource.')
param name string
@description('Location to deploy the resource. Defaults to the location of the resource group.')
param location string = resourceGroup().location
@description('Tags for the resource.')
param tags object = {}

@description('SKU information for VPN Gateway. This must be either Standard or HighPerformance to work with OpenVPN. Defaults to VpnGw1.')
@allowed([
  'Standard'
  'HighPerformance'
  'VpnGw1AZ'
  'VpnGw2AZ'
  'VpnGw3AZ'
  'VpnGw4AZ'
  'VpnGw5AZ'
  'VpnGw1'
  'VpnGw2'
  'VpnGw3'
  'VpnGw4'
  'VpnGw5'
])
param sku string = 'VpnGw1'
@description('Name of the virtual network to which the VPN Gateway will be connected.')
param vnetName string
@description('Address prefix for the virtual network.')
param vnetAddressPrefix string
@description('Name of the public IP address resource to be created for the VPN Gateway.')
param vpnGatewayPublicIpName string
@description('The address prefix for the VPN Gateway subnet.')
param vpnGatewaySubnetAddressPrefix string
@description('Type of the VPN gateway, i.e. RouteBased (dynamic gateway) or PolicyBased (static gateway). Defaults to RouteBased.')
@allowed([
  'RouteBased'
  'PolicyBased'
])
param vpnType string = 'RouteBased'
@description('The IP address range from which VPN clients will receive an IP address when connected. Range specified must not overlap with on-premise network.')
param vpnClientAddressPool string

// Variables

@description('Map of Azure cloud environments to their respective audience IDs.')
var audienceMap = {
  AzureCloud: '41b23e61-6c1e-4545-b367-cd054e0ed4b4'
  AzureUSGovernment: '51bb15d4-3a4f-4ebf-9dca-40096fe32426'
  AzureGermanCloud: '538ee9e6-310a-468d-afef-ea97365856a9'
  AzureChinaCloud: '49f817b6-84ae-4cc0-928c-73f27289b3aa'
}

@description('Tenant ID for the Azure subscription being deployed to.')
var tenantId = subscription().tenantId

@description('The Azure cloud environment in which the deployment is taking place.')
var cloud = environment().name

@description('The audience ID for the Azure cloud environment.')
var audience = audienceMap[cloud]

@description('The login endpoint for the Azure cloud environment.')
var tenant = uri(environment().authentication.loginEndpoint, tenantId)

@description('The issuer URL for the Azure cloud environment.')
var issuer = 'https://sts.windows.net/${tenantId}/'

// Deployments

resource virtualNetwork 'Microsoft.Network/virtualNetworks@2024-05-01' existing = {
  name: vnetName
  scope: resourceGroup()
}

resource vpnGatewaySubnet 'Microsoft.Network/virtualNetworks/subnets@2024-05-01' = {
  name: 'GatewaySubnet'
  parent: virtualNetwork
  properties: {
    addressPrefix: vpnGatewaySubnetAddressPrefix
  }
}

resource vpnGatewayPublicIp 'Microsoft.Network/publicIPAddresses@2024-05-01' = {
  name: vpnGatewayPublicIpName
  location: location
  sku: {
    name: 'Standard'
    tier: 'Regional'
  }
  properties: {
    publicIPAllocationMethod: 'Static'
  }
  tags: tags
}

resource vpnGateway 'Microsoft.Network/virtualNetworkGateways@2024-05-01' = {
  name: name
  location: location
  properties: {
    ipConfigurations: [
      {
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: vpnGatewaySubnet.id
          }
          publicIPAddress: {
            id: vpnGatewayPublicIp.id
          }
        }
        name: 'vnetGatewayConfig'
      }
    ]
    sku: {
      name: sku
      tier: sku
    }
    gatewayType: 'Vpn'
    vpnType: vpnType
    vpnClientConfiguration: {
      vpnClientAddressPool: {
        addressPrefixes: [
          vpnClientAddressPool
        ]
      }
      vpnClientProtocols: [
        'OpenVPN'
      ]
      vpnAuthenticationTypes: [
        'AAD'
      ]
      aadTenant: tenant
      aadAudience: audience
      aadIssuer: issuer
    }
    customRoutes: {
      addressPrefixes: [
        vnetAddressPrefix
      ]
    }
  }
}

// Outputs

@description('ID for the deployed VPN Gateway resource.')
output id string = vpnGateway.id
@description('Name for the deployed VPN Gateway resource.')
output name string = vpnGateway.name
@description('Public IP address for the deployed VPN Gateway resource.')
output publicIp string = vpnGatewayPublicIp.properties.ipAddress
