# Script to export Azure AD role assignments, RBAC role assignments from a chosen subscription and MS Graph app role assignments for users and Service Principals.
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

# Exportfiles are defined here
$date = Get-Date -Format 'dd_MM_yyyy-HH_mm_ss'
$AzRoleAssignmentsCSV = "$env:USERPROFILE\Desktop\$date`_AzRoleAssignments.csv"
$AzureADRoleAssignmentsCSV = "$env:USERPROFILE\Desktop\$date`_AzureADRoleAssignments.csv"
$MSGraphUserAppRoleAssignmentsCSV = "$env:USERPROFILE\Desktop\$date`_MSGraphUserAppRoleAssignments.csv"
$MSGraphSPAppRoleAssignmentsCSV = "$env:USERPROFILE\Desktop\$date`_MSGraphSPAppRoleAssignments.csv"

# Connect to Azure using Az module...
Write-Host "Connecting to Azure using Az module..."
Connect-AzAccount

# Get Subscriptions and ask user which subscription to audit for the RBAC role assignments
$SubList = Get-AzSubscription

$choices="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ!""#%&/()=?*+-_"
# Prompt for subscription choice if more than one
if($SubList.count -gt 1)
{
	$options = [System.Management.Automation.Host.ChoiceDescription[]]@()
      for($p=0; $p -lt $SubList.count; $p++)
      {
      	$options += New-Object System.Management.Automation.Host.ChoiceDescription "&$($choices[$p % $choices.Length]) $($SubList[$p])"
	}
    $userchoice = $host.UI.PromptForChoice("Choose the subscription to audit the RBAC role assignments","The following subscriptions are available to the current login:",$options,0)
    $SubToAudit = $SubList[$userchoice].Id
}else{
    $SubToAudit = $SubList.Id
}
$subScope = "/subscriptions/$($SubToAudit)"

# Connect to Azure using AzureAD module...
Write-Host "Connecting to Azure using AzureAD module..."
Connect-AzureAD
#############################
# Start main part of script #
#############################

############# RBAC role assignments #############
Write-Host "Collecting Azure RBAC role assignments..."
$AllAzRoleAssignmentsList = @()
try {
    $AllAzRoleAssignments = Get-AzRoleAssignment -Scope $subScope 
    foreach($AzRoleAssignment in $AllAzRoleAssignments){
        if($AzRoleAssignment.ObjectType -like "Group"){
            $RoleDefinitionName = $AzRoleAssignment.RoleDefinitionName
            $GroupMembers = Get-AzureADGroupMember -ObjectId (Get-AzureADGroup -SearchString "$($AzRoleAssignment.DisplayName)" |select -ExpandProperty ObjectId) | select ObjectId,ObjectType,DisplayName
            foreach($GroupMember in $GroupMembers){
                $data = [PSCustomObject]@{
                    Subscription = $($SubToAudit)
                    ObjectId = $GroupMember.ObjectId
                    ObjectType = $GroupMember.ObjectType
                    DisplayName = $GroupMember.DisplayName
                    SignInName = $AzRoleAssignment.SignInName
                    RoleDefinitionName = $RoleDefinitionName
                    Scope = $AzRoleAssignment.Scope
                    CanDelegate = $AzRoleAssignment.CanDelegate
                    Note = "Added via Group $($AzRoleAssignment.DisplayName)"
                }
                $AllAzRoleAssignmentsList += $data
            }
        }else{
            $data = [PSCustomObject]@{ 
                Subscription = $($SubToAudit)
                ObjectId = $AzRoleAssignment.ObjectId
                ObjectType = $AzRoleAssignment.ObjectType
                DisplayName = $AzRoleAssignment.DisplayName
                SignInName = $AzRoleAssignment.SignInName
                RoleDefinitionName = $AzRoleAssignment.RoleDefinitionName
                Scope = $AzRoleAssignment.Scope
                CanDelegate = $AzRoleAssignment.CanDelegate
                Note = "N/A"
            }
            $AllAzRoleAssignmentsList += $data
        }
    }
    $AllAzRoleAssignmentsList | Export-CSV -NoTypeInformation -Path $AzRoleAssignmentsCSV
}
catch {
    Write-Warning "There was an error when trying to get the Azure RBAC role assignments for the subscription $($SubToAudit)!"
}

############# AzureAD role assignments #############
Write-Host "Collecting Azure AD role assignments..."
try{
    $UserRoles = Get-AzureADDirectoryRole | ForEach-Object {
        $Role = $_
        $RoleDisplayName = $_.DisplayName
        $RoleMembers = Get-AzureADDirectoryRoleMember -ObjectID $Role.ObjectID
        ForEach ($Member in $RoleMembers) {
            $RoleMembership = [PSCustomObject]@{
                MemberName = $Member.DisplayName
                MemberID = $Member.ObjectID
                MemberOnPremID = $Member.OnPremisesSecurityIdentifier
                MemberUPN = $Member.UserPrincipalName
                MemberType = $Member.ObjectType
                RoleID = $Role.RoleTemplateId
                RoleDisplayName = $RoleDisplayName
            }
            $RoleMembership
        }
    }
    $UserRoles | Export-CSV -NoTypeInformation -Path $AzureADRoleAssignmentsCSV
}catch{
    Write-Warning "There was an error when trying to get the Azure AD role assignments!"
}

############# MS Graph permissions #############
Write-Host "Collecting app role assignments from MS Graph..."
try{
    $Headers = Get-AzureGraphToken
    # Get all service principals
    $SPsURI = "$MSGraphURL/v1.0/servicePrincipals"
    $SPObjects = $null
    $ServicePrincipals = $null
    Write-Host "Collecting Service Principals in environment..."
    do{
        $ServicePrincipals = Invoke-RestMethod `
            -Headers $Headers `
            -URI $SPsURI `
            -UseBasicParsing `
            -Method "GET" `
            -ContentType "application/json"
        if($ServicePrincipals.value){
            $SPObjects += $ServicePrincipals.value 
        }else{
            $SPObjects += $ServicePrincipals
        }
        $SPsURI = $ServicePrincipals.'@odata.nextlink'
    } until (!($SPsURI))

    # Get all users
    $UsersURI = "$MSGraphURL/v1.0/users"
    $UsersObjects = $null	
    $Users = $null
    Write-Host "Collecting Users in environment..."
    do{
        $Users = Invoke-RestMethod `
            -Headers $Headers `
            -URI $UsersURI `
            -UseBasicParsing `
            -Method "GET" `
            -ContentType "application/json"
        if($Users.value){
            $UsersObjects += $Users.value 
        }else{
            $UsersObjects += $Users
        }
        $UsersURI = $Users.'@odata.nextlink'
    } until (!($UsersURI))

    # Get User AppRoleAssignments
    $UserIDs = ($UsersObjects).id
    $UserAppRoleAssignments = $null
    ForEach ($id in $UserIDs){
        $req = $null
        $UserAppRoleAssignmentURL = 'https://graph.microsoft.com/v1.0/users/{0}/appRoleAssignments' -f $id
        $req = Invoke-RestMethod -Headers $Headers `
            -Uri $UserAppRoleAssignmentURL `
            -Method GET
        $UserAppRoleAssignments += $req.value
    }
    if(($UserAppRoleAssignments | measure).Count -gt 0){
        $UserAppRoleAssignments | Export-CSV -NoTypeInformation -Path $MSGraphUserAppRoleAssignmentsCSV
    }else{
        "None identified" | Out-File -FilePath $MSGraphUserAppRoleAssignmentsCSV
    }

    # Get SP AppRoleAssignments
    $ServicePrincipalIDs = ($SPObjects).id
    $SPAppRoleAssignments = $null
    ForEach ($id in $ServicePrincipalIDs){
        $req = $null
        $SPAppRoleAssignmentURL = 'https://graph.microsoft.com/v1.0/servicePrincipals/{0}/appRoleAssignments' -f $id
        $req = Invoke-RestMethod -Headers $Headers `
            -Uri $SPAppRoleAssignmentURL `
            -Method GET
        $SPAppRoleAssignments += $req.value
    }
    if(($SPAppRoleAssignments | measure).Count -gt 0){
        $SPAppRoleAssignments | Export-CSV -NoTypeInformation -Path $MSGraphSPAppRoleAssignmentsCSV
    }else{
        "None identified" | Out-File -FilePath $MSGraphSPAppRoleAssignmentsCSV
    }
}catch{
    Write-Warning "There was an error when trying to get the MS Graph API app role assignments!"
}

Write-Host "Script finished! You can find the csv files here: `r`n$AzRoleAssignmentsCSV`r`n$AzureADRoleAssignmentsCSV`r`n$MSGraphUserAppRoleAssignmentsCSV`r`n$MSGraphSPAppRoleAssignmentsCSV"