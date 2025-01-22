<#
# Script to work with Entra ID administrative units via MS Graph API
# WIP, 23/09/2024, github.com/ville87
#>
$MSGraphURL             = "https://graph.microsoft.com"
function Get-AzureGraphToken {
    $APSUser = Get-AzContext *>&1 
    $resource = "$MSGraphURL"
    $Token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($APSUser.Account, $APSUser.Environment, $APSUser.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, $resource).AccessToken
    $Headers = @{}
    $Headers.Add("Authorization","Bearer"+ " " + "$($token)")
    $Headers.Add("Content-Type","application/json")
    $Headers
}

$tenantid = Read-Host "Please provide the tenantId"
$ConnectAzAcc = Connect-AzAccount -TenantID $tenantId
$Headers = Get-AzureGraphToken

# List Entra ID administrative units via MSGraph API
$administrativeUnitsURL = "$MSGraphURL/v1.0/directory/administrativeUnits"
$administrativeUnitsResponse = Invoke-RestMethod -Headers $Headers -Uri $administrativeUnitsURL -Method Get
$administrativeUnits = $administrativeUnitsResponse.value

Write-Host "Following Administrative Units were found: $administrativeUnits"

# TODO: Add POST
<#
POST https://graph.microsoft.com/v1.0/directory/administrativeUnits
Content-type: application/json

{
    "displayName": "Seattle District Technical Schools",
    "description": "Seattle district technical schools administration",
    "visibility": "HiddenMembership"
}

#>