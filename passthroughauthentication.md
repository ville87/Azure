# Azure Pass Through Authentication (PTA)
## Technical Deep Dive
https://o365blog.com/post/pta-deepdive/
-  Authentication is done from the PTA Agent (installed on system on-prem) using a certificate which is issued by hisconnectorregistrationca.msappproxy.net with the subject being the tenant ID
- Configuration is stored in an xml: C:\ProgramData\Microsoft\Azure AD Connect Authentication Agent\Config\TrustSettings.xml
- The certificate, including the private key protected by the data protection API (DPAPI), can be exported with tools such as AADInternals and Mimikatz.
- PTA relies on PTA agents installed on one or more on-premises servers. Microsoft [recommends](https://docs.microsoft.com/en-us/azure/active-directory/hybrid/how-to-connect-pta-quick-start) installing a minimum of three agents for high availability.


![AzureADSecureworks](/images/AzureAD-pta-flaws-1.png)
High-level PTA architecture. (Source: Secureworks)   
1. A user accesses a service that uses the Azure AD identity platform (e.g., Microsoft 365) and provides their username and password.
2. Azure AD encrypts the credentials and sends an authentication request to one or more PTA agents.
3. The PTA agent decrypts the user’s credentials, attempts to log in to Active Directory with decrypted credentials, and returns results to Azure AD.
