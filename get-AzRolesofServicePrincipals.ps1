[string] $Delimiter = "," # Change this delimiter for localization support of CSV import into Excel
[string] $ExportDir = (Join-Path ([Environment]::GetFolderPath("Desktop")) 'ExportDir') # Change path here if you don't want the generated CSV to be stored on the current users desktop
$ModuleArray = @("Az")

ForEach ($ReqModule in $ModuleArray){
    If ($null -eq (Get-Module $ReqModule -ListAvailable -ErrorAction SilentlyContinue)){
        Install-Module -Name $ReqModule -Force
        Import-Module -Name $ReqModule
    } ElseIf ($null -eq (Get-Module $ReqModule -ErrorAction SilentlyContinue)){
        Import-Module -Name $ReqModule
    }
}
# Authenticate to the tenant
Connect-AzAccount
# create output dir
If (!(Test-Path $ExportDir)){
    New-Item -Path $ExportDir -ItemType "Directory" -Force
}
# Get all Subscriptions
$subs = Get-AzSubscription
$SPRoles = @()
# Foreach subscription, get the resource groups
foreach($sub in $subs){
    # Set the context to the current sub and get all resource groups
    Set-AzContext -SubscriptionObject $sub
    $currentsub = $sub.Name
    $SubRGs = Get-AzResourceGroup
    foreach($SubRG in $SubRGs){
        $currentRG = $SubRG.ResourceGroupName
        # Get all role assignments of service principals in this RG
        $SubRGSPRoles = Get-AzRoleAssignment -ResourceGroupName $SubRG.ResourceGroupName | where-Object { $_.ObjectType -eq "ServicePrincipal" }
        foreach($SubRGSPRole in $SubRGSPRoles){
            # Get the SP details
            $currentSP = Get-AzADServicePrincipal -ObjectId $SubRGSPRole.ObjectId
            # Write all entries into object
            $data = @{
                SubscriptionName = $currentsub
                ResourceGroupName = $currentRG
                ServicePrincipalName = $currentSP.DisplayName
                ServicePrincipalObjectID = $currentSP.Id
                RoleDefinitionName = $SubRGSPRole.RoleDefinitionName
                RoleDefinitionId = $SubRGSPRole.RoleDefinitionId
                CanDelegate = $SubRGSPRole.CanDelegate
            }
            $SPRoles += New-Object psobject -Property $data
        }
    }
}
$SPRoles | Export-Csv $ExportDir\AzADSPRoleAssignments.csv -NoTypeInformation -Delimiter $Delimiter
