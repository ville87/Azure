$availablesubs = Get-AzSubscription
foreach($availablesub in $availablesubs){
	$subname = $availablesub.Name
        $subid = $availablesub.Id
        write-host "Subscriptionname: $subname`t`t`tSubscriptionID: $subid" 
}
$chosensub = Read-Host "Please provide the ID of the subscription you want to assess"
Get-AzSubscription -SubscriptionId $chosensub | Set-AzContext
