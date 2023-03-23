# Query MDI Alerts via MS Graph API

```powershell
# Query MS Graph API for MDI incidents
# Follow app registration on: https://learn.microsoft.com/en-us/microsoft-365/security/defender/api-hello-world?view=o365-worldwide#register-an-app-in-azure-active-directory

################################ GET TOKEN #############################################
# Paste in your tenant ID, client ID and app secret (App key).
function Get-MSGraphToken {
    $tenantId = 'xxxxxxxxxx-xxxx-xxxx-xxxx-xxxxxx' # Paste your directory (tenant) ID here
    $clientId = 'xxxxxxxxxx-xxxx-xxxx-xxxx-xxxxxx' # Paste your application (client) ID here
    $appSecret = 'xxxxxxxxxxxxxxxxxxx' # # Paste your own app secret here to test, then store it in a safe place!

    $resourceAppIdUri = 'https://api.security.microsoft.com'
    $oAuthUri = "https://login.windows.net/$tenantId/oauth2/token"
    $authBody = [Ordered] @{
    resource = $resourceAppIdUri
    client_id = $clientId
    client_secret = $appSecret
    grant_type = 'client_credentials'
    }
    $authResponse = Invoke-RestMethod -Method Post -Uri $oAuthUri -Body $authBody -ErrorAction Stop
    $token = $authResponse.access_token
    # Out-File -FilePath "$env:userprofile\Desktop\Latest-token.txt" -InputObject $token
    return $token
}

################################ GET INCIDENTS #############################################
$token = Get-MSGraphToken

# Get incidents from the past 48 hours.
# The script may appear to fail if you don't have any incidents in that time frame.
$dateTime = (Get-Date).ToUniversalTime().AddHours(-48).ToString("o")

# This URL contains the type of query and the time filter we created above.
# Note that `$filter` does not refer to a local variable in our script --
# it's actually an OData operator and part of the API's syntax.
$url = "https://api.security.microsoft.com/api/incidents`?`$filter=lastUpdateTime+ge+$dateTime"

# Set the webrequest headers
$headers = @{
    'Content-Type' = 'application/json'
    'Accept' = 'application/json'
    'Authorization' = "Bearer $token"
}

# Send the request and get the results.
$response = Invoke-WebRequest -Method Get -Uri $url -Headers $headers -ErrorAction Stop

# Extract the incidents from the results.
$incidents =  ($response | ConvertFrom-Json).value | ConvertTo-Json -Depth 99

# Get a string containing the execution time. We concatenate that string to the name 
# of the output file to avoid overwriting the file on consecutive runs of the script.
$dateTimeForFileName = Get-Date -Format o | foreach {$_ -replace ":", "."}

# Save the result as json
$outputJsonPath = "$env:userprofile\Desktop\Latest-Incidents-$dateTimeForFileName.json"

Out-File -FilePath $outputJsonPath -InputObject $incidents
################################ QUERY INCIDENTS JSON #############################################
$incidentsjson = Get-Content $outputJsonPath | ConvertFrom-Json
$incidentsjson | % { $_.alerts | select firstActivity,title,description,severity,devices | fl}
```
