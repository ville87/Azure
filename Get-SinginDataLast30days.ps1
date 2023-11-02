# This gets all signin data of the last 30 days in your tenant
# Note: Change the timestamps in the URL so that they fit the last 30 days!
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
$tenantId = Read-host "Please provide the tenant Id"
$ConnectAzAcc = Connect-AzAccount -TenantID $tenantId
$Headers = Get-AzureGraphToken
$URI = 'https://graph.microsoft.com/beta/auditLogs/signIns?api-version=beta&$filter=(createdDateTime ge 2023-08-01T22:58:32.666Z and createdDateTime lt 2023-11-01T22:58:32.666Z)&$top=999&$orderby=createdDateTime desc&source=adfs' 
$Results = $null
$SignIns = $null
do {
    $Results = Invoke-RestMethod -Headers $Headers -URI $URI -UseBasicParsing -Method "GET"
    if ($Results.value) {
        $SignIns += $Results.value
    } else {
        $SignIns += $Results
    }
    $uri = $Results.'@odata.nextlink'
} until (!($uri))
