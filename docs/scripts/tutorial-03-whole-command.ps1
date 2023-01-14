


## Login to Azure Portal account 
## - Note that this is interactive, and will launch a browser window to do login
Connect-AzAccount



## Configurations

### GitHub
$githubOrganisationName = 'RogerHowellDfE'
$githubRepositoryName = 'IaC-CI-CD-Learning'

###
$branchName = 'tutorial-03'
$tutorialSuffix = "-$($branchName)"

### AD Application
$adApplicationDisplayName = "bicep-ci-cd-learning-github-workflow$($tutorialSuffix)"
$adApplicationName = "bicep-ci-cd-learning-github-workflow$($tutorialSuffix)"

### Resource Group
$resourceGroupName = "Xyz$($tutorialSuffix)"
$resourceGroupLocation = 'uksouth'


Write-Host "githubOrganisationName      : $($githubOrganisationName)"
Write-Host "githubRepositoryName        : $($githubRepositoryName)"
Write-Host "branchName                  : $($branchName)"
Write-Host "tutorialSuffix              : $($tutorialSuffix)"
Write-Host "adApplicationDisplayName    : $($adApplicationDisplayName)"
Write-Host "adApplicationName           : $($adApplicationName)"
Write-Host "resourceGroupName           : $($resourceGroupName)"
Write-Host "resourceGroupLocation       : $($resourceGroupLocation)"


## Create new resource group
$resourceGroup = New-AzResourceGroup -Name $($resourceGroupName) -Location $($resourceGroupLocation)

## Show the resource group
Get-AzResourceGroup -Name $($resourceGroupName)


## Create new Azure Active Directory (AD) Application, only if it doesn't already exist
## Not explicitly required, but if check not performed then potential for `$application` to contain multiple values
$applicationRegistration
if(((Get-AzADApplication -DisplayName $adApplicationDisplayName) | measure).Count -gt 0) {
    Write-Error 'Not creating new AD Application Registration - one already exists with this name'
    ## exit 1
} else {
    $applicationRegistration = New-AzADApplication -DisplayName "$($adApplicationDisplayName)"
}

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
## - Below is specifically for the `$(branchName)` branch of this specific repo (also possible to apply to environments, pull requests, tags)
##
$federatedCredentialName_tutorialSpecificBranch = "$($adApplicationName)-github-branch-$($branchName)"
New-AzADAppFederatedCredential `
   -Name $federatedCredentialName_tutorialSpecificBranch`
   -ApplicationObjectId $application.Id `
   -Issuer 'https://token.actions.githubusercontent.com' `
   -Audience 'api://AzureADTokenExchange' `
   -Subject "repo:$($githubOrganisationName)/$($githubRepositoryName):ref:refs/heads/$($branchName)"


# ## Optionally also trigger for main branch
# $federatedCredentialName_mainBranch = "$($adApplicationName)-github-branch-main"
# New-AzADAppFederatedCredential `
#    -Name $federatedCredentialName_mainBranch`
#    -ApplicationObjectId $application.Id `
#    -Issuer 'https://token.actions.githubusercontent.com' `
#    -Audience 'api://AzureADTokenExchange' `
#    -Subject "repo:$($githubOrganisationName)/$($githubRepositoryName):ref:refs/heads/$($branchName)"


## For Tutorial 03, we introduce the use of environments
## This means we ALSO need to grant permission when running in the context of an environment
$federatedCredentialName_environment = "$($adApplicationName)-github-environment-$($branchName)"
New-AzADAppFederatedCredential `
   -Name $federatedCredentialName_environment`
   -ApplicationObjectId $application.Id `
   -Issuer 'https://token.actions.githubusercontent.com' `
   -Audience 'api://AzureADTokenExchange' `
   -Subject "repo:$($githubOrganisationName)/$($githubRepositoryName):environment:$($branchName)"

## See (newly-created) federated permissions here:
## https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Credentials/appId/<REDACTED-APP-ID>/isMSAApp~/false


## Create Service Principal to the application
New-AzADServicePrincipal -AppId $application.AppId


## Assign workflow identity permissions to the (newly-created) resource group
New-AzRoleAssignment `
   -ApplicationId $($application.AppId) `
   -RoleDefinitionName Contributor `
   -Scope $resourceGroup.ResourceId


## Drop the resource group
Remove-AzResourceGroup -Name $($resourceGroupName) -Force

