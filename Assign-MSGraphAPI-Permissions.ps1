# Script to add MS Graph API Permissions to a managed identity

# define the service principal
$mgdidentity = Get-AzureADServicePrincipal -ObjectId d7b92146-bebe-46b7-b762-d2d6a46d0b43

# permission name (note: the following one is a very high privileged permission!)
$permissionname ="RoleManagement.ReadWrite.Directory"

# MS Graph App Id (This is always the same!)
$GraphAppId = "00000003-0000-0000-c000-000000000000"

# Get the Graph SP
$GraphServicePrincipal = Get-AzureADServicePrincipal -Filter "appId eq '$GraphAppId'"

# Get the user defined graph app role
$AppRole = $GraphServicePrincipal.AppRoles | Where-Object {$_.Value -eq $PermissionName -and $_.AllowedMemberTypes -contains "Application"}

# assign the permission
New-AzureAdServiceAppRoleAssignment -ObjectId $mgdidentity.ObjectId -PrincipalId $mgdidentity.ObjectId -ResourceId $GraphServicePrincipal.ObjectId -Id $AppRole.Id

#########################################
# Using the MG module (from: https://stackoverflow.com/a/72905062)

$DestinationTenantId = Read-Host "please provide the tenant Id"
$MsiName = Read-Host "Please provide the name of the system- or user-assigned managed identity" # Name of system-assigned or user-assigned managed service identity. (System-assigned use same name as resource).

# Define permissions to assign here...
$oPermissions = @(
  "Directory.ReadWrite.All"
  "Group.ReadWrite.All"
  "GroupMember.ReadWrite.All"
  "User.ReadWrite.All"
  "RoleManagement.ReadWrite.Directory"
)

$GraphAppId = "00000003-0000-0000-c000-000000000000" # Don't change this.

$oMsi = Get-AzADServicePrincipal -Filter "displayName eq '$MsiName'"
$oGraphSpn = Get-AzADServicePrincipal -Filter "appId eq '$GraphAppId'"

$oAppRole = $oGraphSpn.AppRole | Where-Object {($_.Value -in $oPermissions) -and ($_.AllowedMemberType -contains "Application")}

Connect-MgGraph -TenantId $DestinationTenantId

foreach($AppRole in $oAppRole)
{
  $oAppRoleAssignment = @{
    "PrincipalId" = $oMSI.Id
    #"ResourceId" = $GraphAppId
    "ResourceId" = $oGraphSpn.Id
    "AppRoleId" = $AppRole.Id
  }
  
  New-MgServicePrincipalAppRoleAssignment `
    -ServicePrincipalId $oAppRoleAssignment.PrincipalId `
    -BodyParameter $oAppRoleAssignment `
    -Verbose
}
