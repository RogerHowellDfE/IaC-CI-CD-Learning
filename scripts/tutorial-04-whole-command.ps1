


## Login to Azure Portal account 
## - Note that this is interactive, and will launch a browser window to do login
Connect-AzAccount



## Configurations

### GitHub
$githubOrganisationName = 'RogerHowellDfE'
$githubRepositoryName = 'IaC-CI-CD-Learning'

###
$branchName = 'tutorial-04'
$tutorialSuffix = "-$($branchName)"

### AD Application
$adApplicationDisplayName = "bicep-ci-cd-learning-github-workflow$($tutorialSuffix)"
$adApplicationName = "bicep-ci-cd-learning-github-workflow$($tutorialSuffix)"

### Resource Group
$environmentType = 'nonprod'
# $environmentType = 'prod'
$resourceGroupName = "Xyz$($tutorialSuffix)"
$rgNameWithEnvSuffix = "$($resourceGroupName)-$($environmentType)"
$resourceGroupLocation = 'uksouth'


Write-Host "githubOrganisationName      : $($githubOrganisationName)"
Write-Host "githubRepositoryName        : $($githubRepositoryName)"
Write-Host "branchName                  : $($branchName)"
Write-Host "tutorialSuffix              : $($tutorialSuffix)"
Write-Host "adApplicationDisplayName    : $($adApplicationDisplayName)"
Write-Host "adApplicationName           : $($adApplicationName)"
Write-Host "resourceGroupName           : $($resourceGroupName)"
Write-Host "rgNameWithEnvSuffix         : $($rgNameWithEnvSuffix)"
Write-Host "resourceGroupLocation       : $($resourceGroupLocation)"



## Create new Azure Active Directory (AD) Application, only if it doesn't already exist
## Not explicitly required, but if check not performed then potential for `$application` to contain multiple values
$applicationRegistration
if(((Get-AzADApplication -DisplayName $adApplicationDisplayName) | Measure-Object).Count -gt 0) {
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

### TUTORIAL-SPECIFIC BRANCH
$federatedCredentialName_tutorialSpecificBranch = "$($adApplicationName)-github-branch-$($branchName)"
$federatedCredentialSubject_tutorialSpecificBranch = "repo:$($githubOrganisationName)/$($githubRepositoryName):ref:refs/heads/$($branchName)"
New-AzADAppFederatedCredential `
-Name $federatedCredentialName_tutorialSpecificBranch `
-ApplicationObjectId $application.Id `
-Issuer 'https://token.actions.githubusercontent.com' `
-Audience 'api://AzureADTokenExchange' `
-Subject $federatedCredentialSubject_tutorialSpecificBranch

# ### MAIN BRANCH
# ## Optionally also trigger for main branch
# $federatedCredentialName_mainBranch = "$($adApplicationName)-github-branch-main"
# $federatedCredentialSubject_mainBranch = "repo:$($githubOrganisationName)/$($githubRepositoryName):ref:refs/heads/main"
# New-AzADAppFederatedCredential `
#    -Name $federatedCredentialName_mainBranch `
#    -ApplicationObjectId $application.Id `
#    -Issuer 'https://token.actions.githubusercontent.com' `
#    -Audience 'api://AzureADTokenExchange' `
#    -Subject $federatedCredentialSubject_mainBranch

### ENVIRONMENT-SPECIFIC ENVIRONMENT 
### - Note that the environment name is per environment configuration on GitHub settings
$federatedCredentialName_environment = "$($adApplicationName)-github-environment-$($branchName)-$($environmentType)"
$federatedCredentialSubject_environment = "repo:$($githubOrganisationName)/$($githubRepositoryName):environment:$($branchName) - $($environmentType)"
New-AzADAppFederatedCredential `
   -Name $federatedCredentialName_environment `
   -ApplicationObjectId $application.Id `
   -Issuer 'https://token.actions.githubusercontent.com' `
   -Audience 'api://AzureADTokenExchange' `
   -Subject $federatedCredentialSubject_environment

## See (newly-created) federated permissions here:
## https://portal.azure.com/#view/Microsoft_AAD_RegisteredApps/ApplicationMenuBlade/~/Credentials/appId/<REDACTED-APP-ID>/isMSAApp~/false


## Create Service Principal to the application
New-AzADServicePrincipal -AppId $application.AppId



## Create new resource group
$resourceGroup = New-AzResourceGroup -Name $($rgNameWithEnvSuffix) -Location $($resourceGroupLocation)

## Show the resource group
Get-AzResourceGroup -Name $($resourceGroupName)


## Assign workflow identity permissions to the (newly-created) resource group
New-AzRoleAssignment `
   -ApplicationId $($application.AppId) `
   -RoleDefinitionName Contributor `
   -Scope $resourceGroup.ResourceId


## Drop the resource group
$rgNameWithEnvSuffix = "$($resourceGroupName)-nonprod"
Remove-AzResourceGroup -Name $($rgNameWithEnvSuffix) -Force
