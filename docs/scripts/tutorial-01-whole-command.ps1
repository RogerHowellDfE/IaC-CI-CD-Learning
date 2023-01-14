

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

## Show (newly-created) application details
## Also visible in Web UI: 
## - https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps
Get-AzADApplication -DisplayName $adApplicationDisplayName
Get-AzADApplication -OwnedApplication

## Get reference to application 
## - Note: Mostly interchangable with using `$applicationRegistration`, but `$applicationRegistration` exists only when the application is first created
$application = Get-AzADApplication -DisplayName $adApplicationDisplayName


## Get secrets associated with (newly-created) application

Write-Host "AZURE_TENANT_ID:       $((Get-AzContext).Tenant.Id)"
Write-Host "AZURE_SUBSCRIPTION_ID: $((Get-AzContext).Subscription.Id)"
Write-Host "AZURE_CLIENT_ID:       $((Get-AzADApplication -DisplayName $adApplicationDisplayName).AppId)" ## Instructions state `.ApplicationId`, but actually `.AppId`



## Create Azure AD Application Federated Credentials for the (newly-created) AD Application Registration to be accessed by GitHub
## See tutorial 02 for addiitonal detail about this (short version: we're telling Azure which GitHub credentials are permitted)
## 
## - Below is specifically for the main branch of this specific repo (also possible to apply to environments, pull requests, tags)
##
New-AzADAppFederatedCredential `
   -Name "$($adApplicationName)" `
   -ApplicationObjectId $applicationRegistration.Id `
   -Issuer 'https://token.actions.githubusercontent.com' `
   -Audience 'api://AzureADTokenExchange' `
   -Subject "repo:$($githubOrganisationName)/$($githubRepositoryName):ref:refs/heads/main"

## See (newly-created) federated permissions here:
## https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Credentials/appId/<REDACTED-APP-ID>/isMSAApp~/false



## Create new resource group
$resourceGroup = New-AzResourceGroup -Name $($resourceGroupName) -Location $($resourceGroupLocation)

## Show the resource group
Get-AzResourceGroup -Name $($resourceGroupName)


## Assign workflow identity permissions to the (newly-created) resource group
New-AzADServicePrincipal -AppId $application.AppId
New-AzRoleAssignment `
   -ApplicationId $($application.AppId) `
   -RoleDefinitionName Contributor `
   -Scope $resourceGroup.ResourceId


## Drop the resource group
```
Remove-AzResourceGroup -Name $($resourceGroupName) -Force
```
