# Source: https://gist.github.com/LuemmelSec/726307e7dc62dbbf1330bdf12acd2c5c
# A simple PowerShell script to check to which apps the user consented to and which permissions were granted

# Install the required PowerShell modules if they're not already installed
Install-Module -Name AzureAD

# Connect to Azure AD
Connect-AzureAD

# Get the user object for the signed-in user. UPN e.g. administrator@yourcompany.onmicrosoft.com
$user = Get-AzureADUser -ObjectId (Get-AzureADUser -SearchString "<your user principal name>").ObjectId

# Get the OAuth2PermissionGrants for the user
$consents = Get-AzureADUserOAuth2PermissionGrant -ObjectId $user.ObjectId

foreach ($consent in $consents) {
     $app = Get-AzureADServicePrincipal -ObjectId $consent.ClientId
     Write-Host "App Name: " $($app.DisplayName) 
     Write-Host "App ID: " $($app.AppId)
     Write-Host "Consent given: " $consent.Scope
}
