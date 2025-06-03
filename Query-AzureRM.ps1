# Scripting examples to query data via Azure RM
[string]$AzRMURL                = "https://management.azure.com"

# Only used for MS Graph API token...
<# [string]$MSGraphURL = "https://graph.microsoft.com"
function Get-AzureGraphToken {
    $APSUser = Get-AzContext *>&1 
    $resource = "$MSGraphURL"
    $Token = [Microsoft.Azure.Commands.Common.Authentication.AzureSession]::Instance.AuthenticationFactory.Authenticate($APSUser.Account, $APSUser.Environment, $APSUser.Tenant.Id.ToString(), $null, [Microsoft.Azure.Commands.Common.Authentication.ShowDialog]::Never, $null, $resource).AccessToken
    $Headers = @{}
    $Headers.Add("Authorization","Bearer"+ " " + "$($token)")
    $Headers.Add("Content-Type","application/json")
    $Headers
}
#>

function Get-AzureRMToken {
    $azContext = Get-AzContext
    $azProfile = [Microsoft.Azure.Commands.Common.Authentication.Abstractions.AzureRmProfileProvider]::Instance.Profile
    $profileClient = New-Object -TypeName Microsoft.Azure.Commands.ResourceManager.Common.RMProfileClient -ArgumentList ($azProfile)
    if($null -eq $azContext.Subscription.TenantId){
        # Had to add this for environments without Azure Subscription (M365 only)
        $token = $profileClient.AcquireAccessToken($azContext.Tenant.Id)
    }else{
        $token = $profileClient.AcquireAccessToken($azContext.Subscription.TenantId)
    }
    $authHeader = @{
        'Content-Type'='application/json'
        'Authorization'='Bearer ' + $token.AccessToken
    }
    $authHeader
}

Import-Module Az.Accounts -ErrorAction Stop
Import-Module Az.Resources -ErrorAction Stop
$tenantId = Read-host "Please provide the tenant Id"
$ConnectAzAcc = Connect-AzAccount -TenantID $tenantId
# Only used for MS Graph API token...
#$Headers = Get-AzureGraphToken
# Get Token for Azure RM
$authHeader = Get-AzureRMToken
        
# List all available subscriptions and let the user choose which one(s) to review
$restUri = "$AzRMURL/subscriptions/?api-version=2020-01-01"
$subscriptions = Invoke-RestMethod -Uri $restUri -Method Get -Headers $authHeader
$subscriptionsobj = $subscriptions.value

for($i=0;$i-le $Subscriptionsobj.count-1;$i++){"Index: {0} --> {1}" -f $i,"SubscriptionId: $($Subscriptionsobj[$i].SubscriptionId)  - SubscriptionName: $($Subscriptionsobj[$i].displayName)`r`n"}
do{
    $continue = $true
    $ChosenSubs = ((Read-Host -Prompt "Please select the Subscription(s) you want to assess by specifying the index number(s) as a comma separated list") -split ',').Trim()
    $ChosenSubs | ForEach-Object { if($_ -notmatch "^[\d\.]+$"){ Write-host "Please specify only the index number!"; $continue = $false }elseif((!($_ -le $subscriptionsobj.count)) -and ($null -ne $_)){write-host "You specified an index out of range!"; $continue = $false} }
}while($continue -eq $false)

$SubscriptionsToAudit = @()
foreach($chosensubentry in $ChosenSubs){
    $chosensubentryId = $subscriptionsobj[([int]::Parse($chosensubentry))].subscriptionId
    $SubscriptionsToAudit += $chosensubentryId
}

# Get all Security recommendations (assessments)
$assessmentsurl = "$AzRMURL/subscriptions/$SubscriptionEntry/providers/Microsoft.Security/assessments?api-version=2020-01-01"
$assessmentsresponse = Invoke-RestMethod -Headers $authHeader -URI $assessmentsurl  -UseBasicParsing -Method "GET"

# Limit results to only virtual machine resources
$assessmentsresponse.value |? { $_.id -match "virtualMachines" } | fl


# Get all resources
$AllResources = @()
foreach($SubscriptionEntry in $SubscriptionsToAudit){
    $CurrentSubResURL = "$AzRMURL/subscriptions/$SubscriptionEntry/resources?api-version=2021-04-01"
    $CurrentSubResources = $null
        do{
            $CurrentSubResources = Invoke-RestMethod -Headers $authHeader -URI $CurrentSubResURL -UseBasicParsing -Method "GET"
            if(($CurrentSubResources.value |Measure-Object).count -gt 0){
                $AllResources += $CurrentSubResources.value 
            }
            $CurrentSubResURL = $CurrentSubResources.'@odata.nextlink'
        } until (!($CurrentSubResURL))
        Write-Host "Found $($AllResources.count) resources in Subscription $SubscriptionEntry"
}
