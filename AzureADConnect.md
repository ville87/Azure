# Azure AD Connect
Azure AD Connect creates two users to AD and one to Azure AD.    
On-prem accounts:   
- AAD_012345679ab --> used to run the ADSync service (miiserver.exe)
- MSOL_0123456789ab --> used to perform the actual synchronisation operations.
Azure AD account:   
- Sync_XXXX_0123456789ab@company.onmicrosoft.com where XXXX is the name of the server. The user is given a "Directory synchronisation Accounts" role, which allows it to create, modify, and delete users and set their passwords.


If you have access to a machine where Azure AD connect service is installed and gain access to either the ADSyncAdmins or local Admins, you can retreive credentials for an account capable of doing DCSync: https://blog.xpnsec.com/azuread-connect-for-redteam/

## Decrypting ADSync passwords
https://o365blog.com/post/adsync/   
Dump the AD Connect credentials:   
`Get-AADIntSyncCredentials`   