# Notes about Role Assignments and Abuse Possibilities
## Dangerous Roles and Permissions
Collection of different roles is based on the following blog post https://posts.specterops.io/azure-privilege-escalation-via-service-principal-abuse-210ae2be2a5

MS Graph Permissions: 
- 9e3f62cf-ca93-4989-b6ce-bf83c28f9fe8,RoleManagement.ReadWrite.Directory
- 06b708a9-e830-4db3-a914-8e69da51d44f,AppRoleAssignment.ReadWrite.All

Dangerous Azure AD Roles: 
- Global Administrator
- Privileged Role Administrator
- Privileged Authentication Administrator
- Partner Tier2 Support

Potentially Dangerous Azure AD Roles: (Can be abused if there are highly privileged SPs)   
- Application Administrator
- Authentication Administrator
- Azure AD joined device local administrator
- Cloud Application Administrator
- Cloud device Administrator
- Exchange Administrator
- Groups Administrator
- Helpdesk Administrator
- Hybrid Identity Administrator
- Intune Administrator
- Password Administrator
- User Administrator
- Directory Writers

Collection of Azure AD roles which allow an identity to potentially abuse high privileged service principals:
- Application Administrator
- Cloud Application Administrator
- Hybrid Identity Administrator
- Directory Synchronization Account
- Partner Tier1 Support
- Partner Tier2 Support

Collection of Azure RBAC roles which allow an identity to potentially abuse a high privileged service principal:
- Owner
- Contributor
- Automation Contributor
- User Access Administrator

## Azure App Service Managed Identities
Post: https://posts.specterops.io/abusing-azure-app-service-managed-identity-assignments-c3adefccff95

Summary:   
The only principals that can access the Kudu endpoints that allow for remote code execution are those with one of the following AzureRM roles scoped to the Azure App Service Web App or one of its parent objects:
- Owner
- Contributor
- Website Contributor
Indirect role:   
- User Access Administrator
