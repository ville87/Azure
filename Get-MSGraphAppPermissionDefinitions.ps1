# This script can be used to get all Permissions Definitions for the MS Graph API.
[string]$MSGraphURL = "https://graph.microsoft.com"
function Get-AzureGraphToken {
    # Taken from https://gist.githubusercontent.com/andyrobbins/7c3dd62e6ed8678c97df9565ff3523fb/raw/2543368cc661820bc1d13e21aecab5f472086db2/AuditAppRoles.ps1
    $APSUser = Get-AzContext *>&1 
    $resource = "$MSGraphURL"
    $Token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($APSUser.Account, $APSUser.Environment, $APSUser.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, $resource).AccessToken
    $Headers = @{}
    $Headers.Add("Authorization","Bearer"+ " " + "$($token)")
    $Headers
}
Connect-AzAccount
$Headers = Get-AzureGraphToken
$graphroledefinitionsurl = "$MSGraphURL/v1.0/servicePrincipals?`$filter=appId eq '00000003-0000-0000-c000-000000000000'&`$select=appRoles, oauth2PermissionScopes"
$graphroledefinitions = Invoke-RestMethod -Headers $Headers -Uri $graphroledefinitionsurl -Method Get
# Parse the list with:
$graphroledefinitions.value.appRoles