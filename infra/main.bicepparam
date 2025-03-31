using './main.bicep'

extends './root.bicepparam'

param workloadName = 'ai-document-pipeline'

param raiPolicies = [
  {
    name: workloadName
    mode: 'Blocking'
    prompt: {}
    completion: {}
  }
]

param chatModelDeployment = {
  name: 'gpt-4o'
  model: {
    format: 'OpenAI'
    name: 'gpt-4o'
    version: '2024-11-20'
  }
  sku: {
    name: 'GlobalStandard'
    capacity: 10
  }
  raiPolicyName: workloadName
  versionUpgradeOption: 'OnceCurrentVersionExpired'
}

param identities = []
