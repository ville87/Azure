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
