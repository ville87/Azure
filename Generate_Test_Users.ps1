# This script can be used to create an amount of users in Azure AD (without role assignments / privileges)
# Number of users you want to create:
[int]$usercount = 50

# Specify your Azure AD tenant domain here
$tenantDomain = "test123.onmicrosoft.com"

# login
Write-Host "Connecting to the Azure tenant now, please login with a Global Admin"
$ConnectAzADAcc = Connect-AzureAD -TenantDomain $tenantDomain

if((Get-AzureADDirectoryRole).DisplayName -notcontains "Global Administrator"){
    Write-Warning "You are not logged in as a Global Admin. Please restart the script and login with a Global Admin. Script will abort..."
    Exit
}

# generate Azure AD user names
$userlist = @()
for($i=1;$i -le $usercount;$i++){
    $response = Invoke-RestMethod -Uri "https://randomuser.me/api/" -UseBasicParsing -Method Get
    $name = ($response.results.email -split ("@"))[0]
    $userlist += $name
}

# Test User Creation for Azure AD
Add-Type -AssemblyName 'System.Web'
$UserExport = @()
# Create the users in AzureAD
foreach($userentry in $userlist){
    try{
        $UserUPN = "$userentry@$tenantDomain"
        $PasswordProfile = New-Object -TypeName Microsoft.Open.AzureAD.Model.PasswordProfile
        # generate random password with length of 14 and minimum of 1 alphanumeric
        $PWString = [System.Web.Security.Membership]::GeneratePassword(14,1)
        $PasswordProfile.Password = $PWString
        New-AzureADUser -AccountEnabled $true -DisplayName "$($userentry.split(".")[0]) $($userentry.split(".")[1])" -UserPrincipalName $UserUPN -PasswordProfile $PasswordProfile -MailNickName "$($userentry[0])$($userentry.split(".")[1])"
        $data = [PSCustomObject]@{
            UserUPN = $UserUPN
            UserPW = $PWString
            UserRole = @()
            UserMSGraphAppRole = "N/A"
        }
        $UserExport += $data
    }catch{
        Write-Host "Could not create Azure AD user. Error message:`r`n$($error[0].Exception)`r`nTerminating script..."
        #Exit
    }
}
