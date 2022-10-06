# Accessing Azure AD backend APIs behind portal.azure.com with PowerShell

$context = Get-AzContext
$token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($context.Account, $context.Environment, $context.Tenant.Id, $null, "Never", $null, "74658136-14ec-4630-ad9b-26e160ff0fc6")

$headers = @{"Authorization" = "Bearer $($token.AccessToken)";"x-ms-client-request-id" = [guid]::NewGuid().ToString(); "x-ms-client-session-id" = [guid]::NewGuid().ToString()}
$response = Invoke-RestMethod "https://main.iam.ad.ext.azure.com/api/SecurityDefaults/GetSecurityDefaultStatus" -Headers $headers -Method GET
