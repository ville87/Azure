# Exportfiles defined here
$date = Get-Date -Format 'dd_MM_yyyy-HH_mm_ss'
$AzRoleAssignmentsCSV = "$env:USERPROFILE\Desktop\$date`_AzRoleAssignments.csv"
$AzureADRoleAssignmentsCSV = "$env:USERPROFILE\Desktop\$date`_AzureADRoleAssignments.csv"

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

# RBAC role assignments
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
                    RoleDefinitionName = $RoleDefinitionName
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
                RoleDefinitionName = $AzRoleAssignment.RoleDefinitionName
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

# AzureAD role assignments
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
Write-Host "Script finished! You can find the csv files here: `r`n$AzRoleAssignmentsCSV`r`n$AzureADRoleAssignmentsCSV"