# Using the MG module (from: https://stackoverflow.com/a/72905062)

$DestinationTenantId = Read-Host "please provide the tenant Id"
$ManagedIdentityId = Read-Host "Please provide the Id of the system- or user-assigned managed identity" # Name of system-assigned or user-assigned managed service identity. (System-assigned use same name as resource).

# Define permissions to assign here...
$oPermissions = @(
  "Directory.ReadWrite.All"
  "Group.ReadWrite.All"
  "GroupMember.ReadWrite.All"
  "User.ReadWrite.All"
  "RoleManagement.ReadWrite.Directory"
)

$GraphAppId = "00000003-0000-0000-c000-000000000000" # Don't change this.
Connect-MgGraph -TenantId $DestinationTenantId

$oGraphSpn = Get-MgServicePrincipal -Filter "appId eq '$GraphAppId'"

$oAppRole = $oGraphSpn.AppRoles | Where-Object {($_.Value -in $oPermissions) -and ($_.AllowedMemberTypes -contains "Application")}

foreach($AppRole in $oAppRole)
{
  $oAppRoleAssignment = @{
    "PrincipalId" = $ManagedIdentityId
    #"ResourceId" = $GraphAppId
    "ResourceId" = $oGraphSpn.Id
    "AppRoleId" = $AppRole.Id
  }
  
  New-MgServicePrincipalAppRoleAssignment `
    -ServicePrincipalId $oAppRoleAssignment.PrincipalId `
    -BodyParameter $oAppRoleAssignment `
    -Verbose
}
