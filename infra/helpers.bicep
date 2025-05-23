@description('Get the expected name of the resource group for a resource deployment based on either the new or existing resource group.')
@export()
func resourceGroupScope(resourceGroupName string, existing bool, existingResourceGroupName string) string =>
  existing ? existingResourceGroupName : resourceGroupName
