[string]$MSGraphURL             = "https://graph.microsoft.com"
function Get-AzureGraphToken {
    $APSUser = Get-AzContext *>&1 
    $resource = "$MSGraphURL"
    $Token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($APSUser.Account, $APSUser.Environment, $APSUser.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, $resource).AccessToken
    $Headers = @{}
    $Headers.Add("Authorization","Bearer"+ " " + "$($token)")
    $Headers.Add("Content-Type","application/json")
    $Headers
}
$tenantId = Read-host "Please provide the tenant Id"
$ConnectAzAcc = Connect-AzAccount -TenantID $tenantId
$userlistfile = Read-Host "Please provide the full file path to the textfile containing the list of User UPNs"
$userlistfile = $userlistfile -replace ('"','')
$userlist = Get-content $userlistfile
$Headers = Get-AzureGraphToken

# Get the users signin and pw last changed data
$AllUsersData = @()
$UsersURL = "$MSGraphURL/v1.0/users/?`$select=userPrincipalName,signInActivity,lastPasswordChangeDateTime&`$top=999"
# Add userdata to array
do{
    $UsersResponse = Invoke-RestMethod -Headers $Headers -URI $UsersURL -UseBasicParsing -Method "GET"
    if(($UsersResponse.value |Measure-Object).count -gt 0){
        foreach($responseobject in $UsersResponse.value){
            if($null -ne $($responseobject.signInActivity)){ $signInActivity = $responseobject.signInActivity }else{$signInActivity = "N/A"}
            $data = [PSCustomObject]@{
                userPrincipalName = $responseobject.userPrincipalName
                signInActivity = $signInActivity
                lastPasswordChangeDateTime = $responseobject.lastPasswordChangeDateTime
            }
            $AllUsersData += $data
        }
    }
    $UsersURL = $UsersResponse.'@odata.nextlink'
} until (!($UsersURL))
Write-Host "Found $($AllUsersData.count) users"
#$AllUsersData | ConvertTo-Json | Out-File "$env:userprofile\Desktop\alluserdata.json"
$usersSignInData = @()
foreach($user in $userlist){
    $currentuser = $AllUsersData | Where-Object { $_.userPrincipalName -like $user }
    $usersSignInData += $currentuser
}
$usersSignInData | ConvertTo-Json | out-file "$env:userprofile\Desktop\userssignindata.json"
