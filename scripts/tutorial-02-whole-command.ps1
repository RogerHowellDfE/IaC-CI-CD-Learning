

## NOTE: Nothing "new" in tutorial 02 -- mostly elaboration of single concept from tutorial 01


## Configurations

### GitHub
$githubOrganisationName = 'RogerHowellDfE'
$githubRepositoryName = 'IaC-CI-CD-Learning'

### AD Application
$adApplicationRegistrationDisplayName = 'bicep-ci-cd-learning-github-workflow-tutorial-02'
$adApplicationRegistrationName = 'bicep-ci-cd-learning-github-workflow-tutorial-02'

### Resource Group
$resourceGroupName = 'Xyz-tutorial-02'
$resourceGroupLocation = 'uksouth'



## Login to Azure Portal account
## - Note that this is interactive, and will launch a browser window to do login
az login
Connect-AzAccount


##
##
$subscriptionId = $((Get-AzContext).Subscription.Id)
$tenantId = $((Get-AzContext).Tenant.Id)




## Create new resource group
New-AzResourceGroup -Name $($resourceGroupName) -Location $($resourceGroupLocation)

## Show the resource group
$resourceGroup = Get-AzResourceGroup -Name $($resourceGroupName)



## Create Azure AD Application Registration
az ad app create --display-name $adApplicationRegistrationDisplayName
New-AzADApplication -DisplayName $adApplicationRegistrationDisplayName

## Get reference to application 
## - Note: Mostly interchangable with using `$applicationRegistration`, but `$applicationRegistration` exists only when the application is first created
$application = Get-AzADApplication -DisplayName $adApplicationRegistrationDisplayName




## ID values
## - appId: Application ID
##   - ApplicationID, ClientID -> Related to the Whole thing (app registration, federated credential, service principal, etc)
## - id: Azure Object ID
##   - Relates to the Application registration


## Note that Azure and Azure AD are distinct, not the same thing
## - Potential circumstance: have permissions in Azure, but not Azure AD
##   - Azure: typically have permissions on resources
##   - Azure AD: typically have roles


## Note that display name is not unique
## - Potential for two application registrations to have the same name
## - ... which means potential security risk if mis-applied permissions/roles




## Create AD Service Principal -- i.e., the "thing" that gets permissions assigned to it
az ad sp create --id $application.AppId
New-AzADServicePrincipal -AppId $application.AppId




## Assign a role to the service principal
## (can also be done using bicep, but whatever runs the bicep file will need "Owner" role to be able to grant permissions)
## NOTE: Role assignments can take a few minutes to become active.


###

$federatedCredential_name = 'MyFederatedCredentialName'


## Should apply least permissive role possible
## - Reader
## - Contributor
## - Owner
##
## Note: It's possible to create custom roles with more granular permissions,
## but often best _balance_ is to use one of the built-in roles
$federatedCredential_role = 'Contributor'

## Best practice to be as specific / narrow as possible
## Specific resource group is typically specific enough while still allowing some flexibility
$federatedCredential_scope = "/subscriptions/${subscriptionId}/resourceGroups/${resourceGroupName}"

## It's a good practice to provide a justification for your role assignments by specifying a description.
## A description helps anyone who reviews the role assignments later to understand their purpose,
## and to understand how you decided on the assignee, role, and scope.
$federatedCredential_description = "The deployment workflow for the company's website needs to be able to create resources within the resource group"



az role assignment create `
  --assignee $application.AppId `
  --role $federatedCredential_role `
  --scope $federatedCredential_scope `
  --description $federatedCredential_description

New-AzRoleAssignment `
  -ApplicationId $application.AppId `
  -RoleDefinitionName $federatedCredential_role `
  -Scope $federatedCredential_scope `
  -Description $federatedCredential_description


## Role assignment, using bicep:
##
## https://learn.microsoft.com/en-gb/training/modules/authenticate-azure-deployment-workflow-workload-identities/4-grant-workload-identity-access-azure?pivots=powershell
##
## > Let's look at each argument:
## > 
## > - `name` is a globally unique identifier (GUID) for the role assignment. It's a good practice to use the guid() function in Bicep to create a GUID. To ensure that you create a name that's unique for each role assignment, use the principal ID, role definition ID, and scope as the seed arguments for the function.
## >
## > - `principalType` should be set to ServicePrincipal.
## >
## > - `roleDefinitionId` is the fully qualified resource ID for the role definition that you're assigning. 
## >   You mostly work with built-in roles, so you find the role definition ID in the Azure built-in roles documentation.
## >   For example, the Contributor role has the role definition ID b24988ac-6180-42a0-ab88-20f7382dd24c. 
## >   When you specify it in your Bicep file, you use a fully qualified resource ID, such as 
## >   `/subscriptions/<SUBSCRIPTION-ID>/providers/Microsoft.Authorization/roleDefinitions/b24988ac-6180-42a0-ab88-20f7382dd24c`
## >
## > - `principalId` is the service principal's object ID. 
## >   Make sure you don't use the application ID or the application registration's object ID.
## >
## > - `description` is a human-readable description of the role assignment.
## >
##
##    resource roleAssignment 'Microsoft.Authorization/roleAssignments@2020-04-01-preview' = {
##      name: guid(principalId, roleDefinitionId, resourceGroup().id)
##      properties: {
##        principalType: 'ServicePrincipal'
##        roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', roleDefinitionId)
##        principalId: principalId
##        description: 'The deployment workflow for the company\'s website needs to be able to create resources within the resource group.'
##      }
##    }
##



## Which workflow targets are permitted to trigger this?
$branchName = 'tutorial-02'
$policy = "repo:$($githubOrganisationName)/$($githubRepositoryName):ref:refs/heads/$($branchName)"

New-AzADAppFederatedCredential `
  -Name $federatedCredential_name `
  -ApplicationObjectId $applicationRegistrationObjectId `
  -Issuer 'https://token.actions.githubusercontent.com' `
  -Audience 'api://AzureADTokenExchange' `
  -Subject $policy






## MUST (i.e., very strong "should") have different application registrations for each environment
## - Avoid granting to both dev and prod, for example
## - Must keep separate for best practices / security purposes


## - One workload identity per environment
## - Permissions specific to a single resource group



## Q: Can we create federated identity using bicep?
## A: Multi-faceted
##    - Azure App registration and Federated Identity are part of Azure AD
##      - Cannot manage Azure AD using bicep
##      - Need Web Portal, CLI, or PowerShell
##    - Role assignment is an Azure Resource Manager (ARM) resource
##      - Can do using bicep



## Q: Can we use Azure KeyVault instead of GitHub secrets?
## A: Probably yes, but why would you?
##    - Tenant/Subscription/Client IDs etc are all specific to this repository
##    - No need to reuse
##    - Could set them as environment variables
##    - If in KeyVault, something extra to manage




## Drop the resource group
Remove-AzResourceGroup -Name $($resourceGroupName) -Force



