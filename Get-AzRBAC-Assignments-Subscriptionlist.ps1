# Script to collect RBAC role assignments for specific subscriptions
####################################################################
# Define list of subs to check
$subs = @("xxx-xxx-xxx-xx","xxx-xx-xxx")
$AllAzRBACAssignments = @()
# foreach sub, get all RBAC role assignments
foreach($sub in $subs){
    $AzRBACAssignments = Get-AzRoleAssignment -Scope /subscriptions/$sub
    $AllAzRBACAssignments += $AzRBACAssignments
}
write-host "Found $($AllAzRBACAssignments.count) entries..."
