# Script to take a list of permissions and check them against the AzTier project for their "tier"

$AzureRBACTiers = "https://raw.githubusercontent.com/emiliensocchi/azure-tiering/refs/heads/main/Azure%20roles/tiered-azure-roles.json"
$EntraIDTiers = "https://raw.githubusercontent.com/emiliensocchi/azure-tiering/refs/heads/main/Entra%20roles/tiered-entra-roles.json"
$MSGraphAPITiers = "https://raw.githubusercontent.com/emiliensocchi/azure-tiering/refs/heads/main/Microsoft%20Graph%20application%20permissions/tiered-msgraph-app-permissions.json"

$PermissionTypes = @(
    [PSCustomObject]@{ Index = 1; PermissionType = 'EntraIdRole' }
    [PSCustomObject]@{ Index = 2; PermissionType = 'AzureRBACRole' }
    [PSCustomObject]@{ Index = 3; PermissionType = 'MSGraphAPIPermission' }
)
Write-Host "Please choose a permission type by providing the relevant indexnumber:`n" -ForegroundColor Cyan

$PermissionTypes | ForEach-Object {
    Write-Host "$($_.Index): $($_.PermissionType)"
}

# Read user input
do {
    $selection = Read-Host "`nEnter the index number"
} until ($PermissionTypes.Index -contains $selection)

# Get selected object
$SelectedPermissionType = $PermissionTypes | Where-Object Index -eq $selection

Write-Host "`n[INFO] You selected: $($SelectedPermissionType.PermissionType)" -ForegroundColor Green

# Prompt for roles / permissions
$inputRoles = Read-Host "`nEnter one or more role / permission of the chosen type ($($SelectedPermissionType.PermissionType)) you want to check, must be comma separated"

# Convert to array and clean input
$SelectedRoles = $inputRoles -split ',' | ForEach-Object {
    $_.Trim()
} | Where-Object { $_ -ne '' }

# Output result
Write-Host "`nYou entered the following $($SelectedPermissionType.PermissionType) values:" -ForegroundColor Green
$SelectedRoles | ForEach-Object { Write-Host " - $_" }

Write-Host "The script will now check the relevant tier from the AzTier project..."

switch ($SelectedPermissionType.PermissionType) {
    'AzureRBACRole' {
        $TierData = Invoke-RestMethod -Uri $AzureRBACTiers
        $NameProperty = 'assetName'
    }
    'EntraIdRole' {
        $TierData = Invoke-RestMethod -Uri $EntraIDTiers
        $NameProperty = 'assetName'
    }
    'MSGraphAPIPermission' {
        $TierData = Invoke-RestMethod -Uri $MSGraphAPITiers
        $NameProperty = 'assetName'
    }
    default {
        throw "Unsupported permission type."
    }
}

$TierResults = foreach ($item in $SelectedRoles) {

    $match = $TierData | Where-Object {
        $_.$NameProperty -eq $item
    }

    if ($match) {
        [PSCustomObject]@{
            Name           = $item
            PermissionType = $SelectedPermissionType.PermissionType
            Tier           = $match.tier
            Description    = $match.assetDefinition
        }
    }
    else {
        [PSCustomObject]@{
            Name           = $item
            PermissionType = $SelectedPermissionType.PermissionType
            Tier           = 'Unknown'
            Description    = 'Not found in AzTier mapping'
        }
    }
}

Write-Host "`nAzTier classification results:" -ForegroundColor Cyan
$TierResults | Format-Table -AutoSize