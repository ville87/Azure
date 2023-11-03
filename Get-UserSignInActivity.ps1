# Script to get last user signin activity data from MS Graph API
########### Vars and helper functions ########### 
[string]$MSGraphURL = "https://graph.microsoft.com"
function Get-AzureGraphToken {
    $APSUser = Get-AzContext *>&1 
    $resource = "$MSGraphURL"
    $Token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($APSUser.Account, $APSUser.Environment, $APSUser.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, $resource).AccessToken
    $Headers = @{}
    $Headers.Add("Authorization","Bearer"+ " " + "$($token)")
    $Headers.Add("Content-Type","application/json")
    $Headers
}

########### MAIN ########### 
################### check necessary module ###################
printInfo -info "Checking if required PowerShell modules are available..." -level "INFO"
try{
    Import-Module Az.Accounts -ErrorAction Stop
    Import-Module Az.Resources -ErrorAction Stop
}catch{
    Write-Warning "Required modules could not be imported! Please ensure you have the modules Az.Accounts and Az.Resources installed and restart the script!"
    write-host $Error[0].Exception.Message
    Exit 2
}
########## Login to tenant ########## 
$tenantId = Read-host "Please provide the tenant Id"
$ConnectAzAcc = Connect-AzAccount -TenantID $tenantId
$Headers = Get-AzureGraphToken
########## Collect data ########## 
$AllUsersData = @()
$UsersURL = "$MSGraphURL/v1.0/users/?`$select=userPrincipalName,signInActivity&`$top=999"
# Add userdata to array
do{
    $UsersResponse = Invoke-RestMethod -Headers $Headers -URI $UsersURL -UseBasicParsing -Method "GET"
    if(($UsersResponse.value |Measure-Object).count -gt 0){
        $AllUsersData += $UsersResponse.value
    }
    $UsersURL = $UsersResponse.'@odata.nextlink'
} until (!($UsersURL))
Write-Host "Found $($AllUsersData.count) users.`r`nExporting JSON file to $($env:userprofile)\Desktop\MSGraphUsersignInActivity.json"
$AllUsersData | ConvertTo-Json | Out-File "$env:userprofile\Desktop\MSGraphUsersignInActivity.json"
