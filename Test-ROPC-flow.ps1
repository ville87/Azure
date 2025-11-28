$Creds = Get-Credential -Credential 'user@domain.com' # Change me
$TenantId = 'xxx-xxx-xxx-xxx'  # Change me
$TeamsAppId = '1fec8e78-bce4-4aaf-ab1b-5451cc387264'

$Form = @{
    grant_type = 'password'
    client_id = $TeamsAppId
    username = $Creds.UserName
    password = $Creds.GetNetworkCredential().Password
    scope = 'openid offline_access https://graph.microsoft.com/.default'
}
$Arguments = @{
    Uri = "https://login.microsoftonline.com/$TenantId/oauth2/v2.0/token"
    Method = 'Post'
    ContentType = 'application/x-www-form-urlencoded'
    Body = $Form
}

$Result = Invoke-RestMethod @Arguments
