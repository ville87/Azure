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

$tenantId = Read-Host "Please provide the Entra ID tenant Id"
$tenantId = $tenantId.trim()
# Connect to Azure using Az module
try{
    $ConnectAzAcc = Connect-AzAccount -TenantID $tenantId
}catch{
    printInfo -info "Could not connect to tenant $tenantid. Error: TODO" -level "ERROR"
    Exit #TODO
}
# Get the JWT for MS Graph API
$Headers = Get-AzureGraphToken
# App registration checks
$AllAppRegsData = @()
$AppRegsURL = "$MSGraphURL/v1.0/applications?`$top=999"
do{
    $AppRegsResponse = Invoke-RestMethod -Headers $Headers -URI $AppRegsURL -UseBasicParsing -Method "GET"
    if(($AppRegsResponse.value |Measure-Object).count -gt 0){
        $AllAppRegsData += $AppRegsResponse.value
    }
    $AppRegsURL = $AppRegsResponse.'@odata.nextlink'
} until (!($AppRegsURL))
$AllAppRegsData | ConvertTo-Json | Out-File ".\AllAppRegs-$tenantid.json"
$AppRegSecretsObj = @()
$AllAppRegsData | % {  
    if($_.passwordcredentials -ne $null) {  
        $AppId = $($_.appId) 
        $AppDisplayname = $($_.displayName)
        $_.passwordcredentials | % { 
            # Check if the secret is expiring in more than 5 years
            if((Get-Date -Date $($_.endDateTime)) -gt (Get-Date).AddYears(5) ){
                $data = [pscustomobject]@{
                    AppDisplayName = $AppDisplayName
                    AppId = $AppId
                    SecretName = $($_.displayName)
                    EndDateTime = $($_.endDateTime)
                }
                $AppRegSecretsObj += $data
            }  
        } 
    }
    if($_.keyCredentials -ne $null){
        $AppId = $($_.appId) 
        $AppDisplayname = $($_.displayName)
        $_.keyCredentials | % { 
            # Check if the certificate is expiring in more than 5 years
            if((Get-Date -Date $($_.endDateTime)) -gt (Get-Date).AddYears(5) ){
                $data = [pscustomobject]@{
                    AppDisplayName = $AppDisplayName
                    AppId = $AppId
                    nCertDisplayName = $($_.displayName)
                    EndDateTime = $($_.endDateTime)
                }
                $AppRegSecretsObj += $data
            }
        }
    }
}
if(($AppRegSecretsObj |Measure-Object).count -gt 0){
    Write-Host "Found app registrations with long living secrets or certificates:`n"
    $AppRegSecretsObj |fl
}