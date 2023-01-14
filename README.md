# IaC-CI-CD-Learning

Following tutorials at:

- **Microsoft Learn modules**
  - Guided walkthrough, badged and xp points for doing
  - https://learn.microsoft.com/en-gb/training/paths/bicep-github-actions/
- **Microsoft Learn Live**
  - Video webinar sessions, demonstrations
  - https://aka.ms/learnlive-automate-azure-deployments-bicep-github-actions


## Notes

### Installing command line tools to connect to and interact with Azure

```powershell
## Install Azure Powershell module
## This enables user of `Connect-AzAccount`

## Option (1): Install module
## https://learn.microsoft.com/en-us/powershell/azure/install-az-ps
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force

## Option (2): Download MSI
## https://learn.microsoft.com/en-us/powershell/azure/install-az-ps-msi?view=azps-9.3.0
```


Note, errors about existing packages may be due to installing both Az and AzureRM modules.
Az appears to be the more recent one

```powershell
## Alternative: Azure CLI
## Note that the instructions within the tutorial will not necessarily align exactly
## https://learn.microsoft.com/en-us/cli/azure/
## https://learn.microsoft.com/en-us/cli/azure/install-azure-cli
```

### Workload Identity

https://learn.microsoft.com/en-gb/training/modules/build-first-bicep-deployment-pipeline-using-github-actions/5-exercise-create-github-secret?pivots=powershell

https://learn.microsoft.com/en-gb/training/modules/authenticate-azure-deployment-workflow-workload-identities/



```powershell
$githubOrganisationName = 'RogerHowellDfE'
$githubRepositoryName = 'IaC-CI-CD-Learning'

$adApplicationDisplayName = 'bicep-ci-cd-learning-github-workflow'
$adApplicationName = 'bicep-ci-cd-learning-github-workflow'


$applicationRegistration = New-AzADApplication -DisplayName "$($adApplicationDisplayName)"

New-AzADAppFederatedCredential `
   -Name "$($adApplicationName)" `
   -ApplicationObjectId $applicationRegistration.Id `
   -Issuer 'https://token.actions.githubusercontent.com' `
   -Audience 'api://AzureADTokenExchange' `
   -Subject "repo:$($githubOrganisationName)/$($githubRepositoryName):ref:refs/heads/main"


## OUTPUT:
## Id                                   Audience                     Description Issuer
## --                                   --------                     ----------- ------
## <REDACTED>                           {api://AzureADTokenExchange}             https://token.actions.githubuserconten...

```



This creates a new Active Directory Application Registration

Visable at: https://portal.azure.com/#view/Microsoft_AAD_IAM/ActiveDirectoryMenuBlade/~/RegisteredApps

![](docs/App%20Registrations%20Page%20--%20after%20creating%20an%20app%20via%20command%20line.png)



### Get details about the created application

```powershell
Get-AzADApplication -DisplayName $adApplicationDisplayName

## DisplayName                          Id                                   AppId
## -----------                          --                                   -----
## bicep-ci-cd-learning-github-workflow <REDACTED>                           <REDACTED>
```


### List your "owned" applications

```powershell
## Using 
Get-AzADApplication -OwnedApplication

## DisplayName                          Id                                   AppId
## -----------                          --                                   -----
## bicep-ci-cd-learning-github-workflow <REDACTED>                           <REDACTED>
```


```powershell
## Using AZ CLI
az ad app list --show-mine
```



### Create Resource Group, and grant access

```powershell

$resourceGroupName = 'Xyz'
$resourceGroupLocation = 'uksouth'

$resourceGroup = New-AzResourceGroup -Name $($resourceGroupName) -Location $($resourceGroupLocation)

New-AzADServicePrincipal -AppId $applicationRegistration.AppId
New-AzRoleAssignment `
   -ApplicationId $($applicationRegistration.AppId) `
   -RoleDefinitionName Contributor `
   -Scope $resourceGroup.ResourceId
```

### Secrets

- Tenant ID
  - `AZURE_TENANT_ID`
  - Also referred to as Directory ID
  - `(Get-AzContext).Tenant.Id`
- Subscription ID
  - `AZURE_SUBSCRIPTION_ID`
  - (Get-AzContext).Subscription.Id
- Client ID
  - `AZURE_CLIENT_ID`
  - Specific to the application / client connecting to Azure
  - Also referred to as the application (client) ID
  - 


```powershell
## Get secrets associated with (newly-created) application

Write-Host "AZURE_TENANT_ID:       $((Get-AzContext).Tenant.Id)"
Write-Host "AZURE_SUBSCRIPTION_ID: $((Get-AzContext).Subscription.Id)"
Write-Host "AZURE_CLIENT_ID:       $((Get-AzADApplication -DisplayName $adApplicationDisplayName).AppId)" ## Instructions state `.ApplicationId`, but actually `.AppId`
```


![](docs/Locating%20Subscription%20ID.png)





