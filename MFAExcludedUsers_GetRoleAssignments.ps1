$tenantID               = Read-Host "Please provide the tenantId of the target Azure AD tenant"
$MSGraphURL             = "https://graph.microsoft.com"
$AzRMURL                = "https://management.azure.com"
$CSVPath                = "$((Get-Location).Path)\MFAExcludedUsers_Roles_$tenantId`_$(Get-Date -Format 'dd_MM_yyyy-HH_mm_ss').csv"
function Get-AzureGraphToken {
    $APSUser = Get-AzContext *>&1 
    $resource = "$MSGraphURL"
    $Token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($APSUser.Account, $APSUser.Environment, $APSUser.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, $resource).AccessToken
    $Headers = @{}
    $Headers.Add("Authorization","Bearer"+ " " + "$($token)")
    $Headers.Add("Content-Type","application/json")
    $Headers
}
function Get-AzureRMToken {
    $azContext = Get-AzContext
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
    if($null -eq $azContext.Subscription.TenantId){
        # Had to add this for environments without Azure Subscription (M365 only)
        $token = $profileClient.AcquireAccessToken($azContext.Tenant.Id)
    }else{
        $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
    }
    $authHeader = @{
        'Content-Type'='application/json'
        'Authorization'='Bearer ' + $token.AccessToken
    }
    $authHeader
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
$RolesList =  New-Object System.Collections.ArrayList
# Get all subscriptions where current logged in user has access to, because we can only audit RBAC role assignments in these...
$authHeader = Get-AzureRMToken
$restUri = "$AzRMURL/subscriptions/?api-version=2020-01-01"
$subscriptions = Invoke-RestMethod -Uri $restUri -Method Get -Headers $authHeader
$subscriptionsobj = $subscriptions.value

foreach($MFAExcludedUser in $ListofMFAExcludedUsers){
    try {
        $null = [mailaddress]$MFAExcludedUser
    }
    catch {
        Write-Warning "The current user $MFAExcludedUser is not in the correct format for a user principal name! Will skip the check for this one..."
        continue
    }
    
    ###############################################################################################
    ################################# Azure AD Role Assignments ###################################
    ###############################################################################################

    Write-Host "Collecting assigned Azure AD roles for user $MFAExcludedUser..."
    $UserId = (Get-AzADUser -UserPrincipalName $MFAExcludedUser).Id
    $AzureADRoleAssignmentsURL = "$MSGraphURL/beta/rolemanagement/directory/transitiveRoleAssignments?`$count=true&`$filter=principalId eq '$UserId'"
    $AzureADRoleAssignmentResponse = Invoke-RestMethod -Headers $MGGraphBetaHeaders -URI $AzureADRoleAssignmentsURL -UseBasicParsing
    $AssignedAzureADRoles = $AzureADRoleAssignmentResponse.value
    if($AssignedAzureADRoles.count -gt 0){
        # Lookup role definition names
        foreach($AssignedAzureADRole in $AssignedAzureADRoles){
            $RoleDefinitionsResponse = Invoke-RestMethod -Uri "https://graph.microsoft.com/v1.0/roleManagement/directory/roleDefinitions?`$filter=Id eq '$($AssignedAzureADRole.roleDefinitionId)'" -Headers $Headers
            $data = [pscustomobject]@{'UserPrincipalName'=$MFAExcludedUser;'RoleType'='AzureAD';'RoleDisplayName'=$RoleDefinitionsResponse.value.displayName;'Scope'='N/A';}
            $RolesList.add($data) | Out-Null
        }
    }else{
        $data = [pscustomobject]@{'UserPrincipalName'=$MFAExcludedUser;'RoleType'='AzureAD';'RoleDisplayName'="None identified";'Scope'='N/A';}
        $RolesList.add($data) | Out-Null

    }

    ###############################################################################################
    ################################# Azure RBAC Role Assignments #################################
    ###############################################################################################
    Write-Host "Collecting assigned Azure RBAC roles for user $MFAExcludedUser..."
    # This has to be done for every subscription we have access to
    foreach($subscription in $subscriptionsobj){
        $AzRBACRoleAssRestUri = "$AzRMURL/subscriptions/$($subscription.subscriptionId)/providers/Microsoft.Authorization/roleAssignments?api-version=2022-04-01&`$filter=assignedTo('$userId')"
        $AzRBACRoleAssignmentResponse = Invoke-RestMethod -Uri $AzRBACRoleAssRestUri -Method Get -Headers $authHeader
        if(($AzRBACRoleAssignmentResponse.value.properties).count -gt 0){
            $UsersAzRBACRoleAssignments = $AzRBACRoleAssignmentResponse.value.properties
            foreach($UsersAzRBACRoleAssignment in $UsersAzRBACRoleAssignments){
                # Get roleDefName from roleDefId
                $UsersAzRBACRoleAssignmentroleDefinitionId = $UsersAzRBACRoleAssignment.roleDefinitionId
                $roleDefIdURL = "$AzRMURL/$UsersAzRBACRoleAssignmentroleDefinitionId`?api-version=2022-04-01"
                $roleDefResponse = Invoke-RestMethod -Uri $roleDefIdURL -Method Get -Headers $authHeader
                $roleDisplayName = $roleDefResponse.properties.roleName
                $data = [pscustomobject]@{'UserPrincipalName'=$MFAExcludedUser;'RoleType'='AzureRBAC';'RoleDisplayName'=$roleDisplayName;'Scope'=$($UsersAzRBACRoleAssignment.scope);}
                $RolesList.add($data) | Out-Null
            }
        }else{
            $data = [pscustomobject]@{'UserPrincipalName'=$MFAExcludedUser;'RoleType'='AzureRBAC';'RoleDisplayName'='None identified';'Scope'='N/A';}
            $RolesList.add($data) | Out-Null
        }
    }
}

Write-Host "Data collection done! Exporting the CSV file..."
$RolesList | Export-Csv -Notypeinformation -Path $CSVPath -Force
Write-Host "File exported to $CSVPath"
Write-Host "Script finished!`r`nPlease note that the logged in user had access to the following subscription(s), therefore the assigned RBAC roles could only be checked for those:"
$subscriptionsobj | Select-Object subscriptionId,tenantId,displayName
