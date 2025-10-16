# List all Storage account blobs immutability policy configurations
# This script requires the module Az.Storage to be installed

# Connect to tenant
$tenant = Read-Host "Please provide tenant domain name or Id"
Connect-AzAccount -Tenant $tenant

# List Resource Groups
Write-Host "Listing all resource groups found..."
$rgs = Get-AzResourceGroup |select ResourceGroupName,ResourceId
$rgs |ft
$ResourceGroupName = Read-Host "Please provide the exact name of the resource group of which you want to check the storage blob settings"
$ResourceGroupName.trim()
# Get Storage Accounts for given subscription
Write-Host "Collecting data of all storage blobs in the Resource Group $ResourceGroupName. This can take a while..."
$results = @()
$storageAccounts = Get-AzStorageAccount -ResourceGroupName $ResourceGroupName
foreach ($account in $storageAccounts) {
    $ctx = $account.Context
    Get-AzStorageContainer -Context $ctx | ForEach-Object {
        $container = $_
        $blobs = Get-AzStorageBlob -Container $container.Name -Context $ctx
        foreach ($blob in $blobs) {
            $policy = $blob.BlobProperties.ImmutabilityPolicy
            $results += [PSCustomObject]@{
                SubscriptionId            = $account.Id.Split('/')[2]
                ResourceGroup             = $account.ResourceGroupName
                StorageAccount            = $account.StorageAccountName
                Container                 = $container.Name
                BlobName                  = $blob.Name
                ImmutabilityPolicyMode    = $policy.PolicyMode
                ImmutabilityUntilDate     = $policy.ExpiresOn.UtcDateTime
            }
        }
    }
}
Write-Host "Done. Results are exported to the file .\StgBlobs-$ResourceGroupName-immutabilitysettings.csv"
$results |Export-Csv -NoTypeInformation -Path .\StgBlobs-$ResourceGroupName-immutabilitysettings.csv