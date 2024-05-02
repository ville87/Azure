# Export all MS Graph App Role Assignments of a tenant
$MSGraphURL             = "https://graph.microsoft.com"
$AzRMURL                = "https://management.azure.com"

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
# First get the name of the approles
$approlesresponse = Invoke-RestMethod -Uri $url -Headers $Headers
$allapproles = $approlesresponse.approles
# Import all exported approleassignments (SPs and Users) from the target environment
# You can get the approleassignments of an environment using the following graph endpoints:
# "https://graph.microsoft.com/v1.0/users/{id}/approleassignments"
# "https://graph.microsoft.com/v1.0/servicePrincipals/{id}/approleassignments"
$allSPapproleassignments = import-csv .\MSGraphAppRoles_ServicePrincipals.csv
$allUserapproleassignments = import-csv .\MSGraphAppRoles_Users.csv
$listofapproleassignments = @()
foreach($approleassignment in $allSPapproleassignments){
    $data = @{
        id = $approleassignment.id
        appRoleId = $approleassignment.appRoleId
        appRoleName = ($allapproles | Where-Object { $_.id -like $approleassignment.appRoleId }).value
        createdDateTime = $approleassignment.createdDateTime
        principalDisplayName = $approleassignment.principalDisplayName
        principalId = $approleassignment.principalId
        principalType = $approleassignment.principalType
        resourceDisplayName = $approleassignment.resourceDisplayName
        resourceId = $approleassignment.resourceId
    }
    $listofapproleassignments += $data
}

foreach($approleassignment in $allUserapproleassignments){
    $data = @{
        id = $approleassignment.id
        appRoleId = $approleassignment.appRoleId
        appRoleName = ($allapproles | Where-Object { $_.id -like $approleassignment.appRoleId }).value
        createdDateTime = $approleassignment.createdDateTime
        principalDisplayName = $approleassignment.principalDisplayName
        principalId = $approleassignment.principalId
        principalType = $approleassignment.principalType
        resourceDisplayName = $approleassignment.resourceDisplayName
        resourceId = $approleassignment.resourceId
    }
    $listofapproleassignments += $data
}

$listofapproleassignments | Export-Csv -NoTypeInformation -Path .\MSGraph_AppRoleAssignments_$tenantid.csv