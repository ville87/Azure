$tenantID               = Read-Host "Please provide the tenantId of the target Azure AD tenant"
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
try{
    Write-Host "Importing necessary modules..."
    Import-Module Az.Accounts -ErrorAction Stop
    Import-Module Az.Resources -ErrorAction Stop
}catch{
    Write-Warning "Required modules could not be imported! Please ensure you have the modules Az.Accounts and Az.Resources installed and restart the script!"
    write-host $Error[0].Exception.Message
    Exit 11
}

Write-Host "Starting login process..."
$ConnectAzAcc = Connect-AzAccount -TenantID $tenantId
$Headers = Get-AzureGraphToken
# add required header for the used beta endpoint
$MGGraphBetaHeaders = $Headers
$MGGraphBetaHeaders.Add("ConsistencyLevel","eventual")

$FileofMFAExcludedUsers = Read-Host "Please provide the full file path to the textfile containing the list of MFA excluded users. The users have to be added in their upn format, e.g. user@domain.com, one user per line"
$FileofMFAExcludedUsers = $FileofMFAExcludedUsers -replace ('"','')
$ListofMFAExcludedUsers = get-Content $FileofMFAExcludedUsers
$ResultArrayList =  New-Object System.Collections.ArrayList
foreach($MFAExcludedUser in $ListofMFAExcludedUsers){
    try {
        $null = [mailaddress]$MFAExcludedUser
    }
    catch {
        Write-Warning "The current user $MFAExcludedUser is not in the correct format for a user principal name! Will skip the check for this one..."
        continue
    }
    Write-Host "Collecting assigned roles for user $MFAExcludedUser..."
    $UserId = (Get-AzADUser -UserPrincipalName $MFAExcludedUser).Id
    $RoleAssignmentsURL = "$MSGraphURL/beta/rolemanagement/directory/transitiveRoleAssignments?`$count=true&`$filter=principalId eq '$UserId'"
    $AzureADRoleAssignmentResponse = Invoke-RestMethod -Headers $MGGraphBetaHeaders -URI $RoleAssignmentsURL -UseBasicParsing
    $AssignedRoles = $AzureADRoleAssignmentResponse.value
    if($AssignedRoles.count -gt 0){
        # Lookup role definition names
        foreach($AssignedRole in $AssignedRoles){
            $RoleDefinitionsResponse = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/roleManagement/directory/roleDefinitions?`$filter=Id eq '$($AssignedRole.roleDefinitionId)'" -Headers $Headers
            $data = [pscustomobject]@{'UserPrincipalName'=$MFAExcludedUser;'RoleDisplayName'=$RoleDefinitionsResponse.value.displayName;}
            $ResultArrayList.add($data) | Out-Null
        }
    }else{
        Write-Host "User has no roles assigned."
        $data = [pscustomobject]@{'UserPrincipalName'=$MFAExcludedUser;'RoleDisplayName'="N/A"}
        $ResultArrayList.add($data) | Out-Null

    }
}

Write-Host "Data collection done! Exporting the CSV file..."
$CSVPath = "$((Get-Location).Path)\MFAExcludedUsers_RoleAssignments_$tenantId`_$(Get-Date -Format 'dd_MM_yyyy-HH_mm_ss').csv"
$ResultArrayList | Export-Csv -Notypeinformation -Path $CSVPath -Force
Write-Host "File exported to $CSVPath. Script finished!"