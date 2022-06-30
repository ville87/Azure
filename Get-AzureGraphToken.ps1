# connect to Azure and get a JWT to connect to MS Graph API

[string]$MSGraphURL = "https://graph.microsoft.com"

function Get-AzureGraphToken {
    # Taken from https://gist.githubusercontent.com/andyrobbins/7c3dd62e6ed8678c97df9565ff3523fb/raw/2543368cc661820bc1d13e21aecab5f472086db2/AuditAppRoles.ps1
    $APSUser = Get-AzContext *>&1 
    $resource = "$MSGraphURL"
    $Token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($APSUser.Account, $APSUser.Environment, $APSUser.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, $resource).AccessToken
    $Headers = @{}
    $Headers.Add("Authorization","Bearer"+ " " + "$($token)")
    $Headers
}

$Headers = Get-AzureGraphToken

# Example to get all Service Principals from MS Graph API
$SPsURI = "$MSGraphURL/v1.0/servicePrincipals"
$TestSPObjects = $null
$ServicePrincipals = $null
do{
    $ServicePrincipals = Invoke-RestMethod `
        -Headers $Headers `
        -URI $SPsURI `
        -UseBasicParsing `
        -Method "GET" `
        -ContentType "application/json"
    if($ServicePrincipals.value){
        $TestSPObjects += $ServicePrincipals.value 
    }else{
        $TestSPObjects += $ServicePrincipals
    }
    $SPsURI = $ServicePrincipals.'@odata.nextlink'
} until (!($SPsURI))
Write-Host "Found $($TestSPObjects.count) objects"
