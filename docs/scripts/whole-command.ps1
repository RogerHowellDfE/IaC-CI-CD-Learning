

## Configurations

### GitHub
$githubOrganisationName = 'RogerHowellDfE'
$githubRepositoryName = 'IaC-CI-CD-Learning'

### AD Application
$adApplicationDisplayName = 'bicep-ci-cd-learning-github-workflow'
$adApplicationName = 'bicep-ci-cd-learning-github-workflow'

### Resource Group
$resourceGroupName = 'Xyz'
$resourceGroupLocation = 'uksouth'


## Login to Azure Portal account 
## - Note that this is interactive, and will launch a browser window to do login
Connect-AzAccount


## Create new Azure Active Directory (AD) Application
$applicationRegistration = New-AzADApplication -DisplayName "$($adApplicationDisplayName)"


## Create Azure AD Application Federated Credentials for the (newly-created) AD Application Registration
New-AzADAppFederatedCredential `
   -Name "$($adApplicationName)" `
   -ApplicationObjectId $applicationRegistration.Id `
   -Issuer 'https://token.actions.githubusercontent.com' `
   -Audience 'api://AzureADTokenExchange' `
   -Subject "repo:$($githubOrganisationName)/$($githubRepositoryName):ref:refs/heads/main"


## Show (newly-created) application details
Get-AzADApplication -DisplayName $adApplicationDisplayName
Get-AzADApplication -OwnedApplication


## Create new resource group
$resourceGroup = New-AzResourceGroup -Name $($resourceGroupName) -Location $($resourceGroupLocation)

## Assign workflow identity permissions to the (newly-created) resource group
New-AzADServicePrincipal -AppId $applicationRegistration.AppId
New-AzRoleAssignment `
   -ApplicationId $($applicationRegistration.AppId) `
   -RoleDefinitionName Contributor `
   -Scope $resourceGroup.ResourceId


## Get secrets associated with (newly-created) application

Write-Host "AZURE_TENANT_ID:       $((Get-AzContext).Tenant.Id)"
Write-Host "AZURE_SUBSCRIPTION_ID: $((Get-AzContext).Subscription.Id)"
Write-Host "AZURE_CLIENT_ID:       $((Get-AzADApplication -DisplayName $adApplicationDisplayName).AppId)" ## Instructions state `.ApplicationId`, but actually `.AppId`



