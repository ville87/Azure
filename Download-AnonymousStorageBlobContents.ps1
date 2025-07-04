# If there are Storage account blobs with anonymous access enabled, you can use the following script to download all the contents:
$destination = "C:\Data\targetfolder"
$allstorageaccs = Get-AzStorageAccount
foreach($storageacc in $allstorageaccs){
    Write-Host "###########################################################################"
    Write-Host "Checking containers in Storage Account $($storageacc.StorageAccountName)..."
    $context = New-AzStorageContext -StorageAccountName $storageacc.StorageAccountName
    $storageacccontainers = Get-AzStorageContainer -Context $context
    foreach($container in $storageacccontainers){
        Write-Host "--------------------------------------------------"
        Write-Host "Checking blobs in container $($container.Name)..."
        $blob = Get-AzStorageBlob -Context $context -Container $container.Name
        if(($blob | Measure-Object).count -gt 1){
            Write-Host "Found more than one blob in the container... Listing the first 5 for logging purposes:`n$($blob.name |select -First 5)"
            Write-Host "Downloading only the first blob found"
            Get-AzStorageBlobContent -Blob $($blob.name |select -First 1) -Container $container.Name -Destination $destination -Context $context
        }elseif(($blob | Measure-Object).count -eq 1){
            Write-Host "Found one blob in container, downloading..."
            Get-AzStorageBlobContent -Blob $blob.name -Container $container.Name -Destination $destination -Context $context
        }else{
            Write-Host "Empty container..."
        }
    }
}
