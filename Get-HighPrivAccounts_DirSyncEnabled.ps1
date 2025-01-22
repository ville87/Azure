$highprivroles = @("Global Administrator","Privileged Role Administrator","Privileged Authentication Administrator","Partner Tier2 Support")

$tenantId = Read-host "Please provide the tenant Id"
Connect-AzureAD -TenantID $tenantId

try{
    $highprivmembers = @()
    foreach($highprivrole in $highprivroles){
        $AzureADRole = Get-AzureADDirectoryRole -Filter "DisplayName eq '$highprivrole'"
        if($null -ne $AzureADRole){
            $members = Get-AzureADDirectoryRoleMember -ObjectId $AzureADRole.ObjectId
            foreach($user in $members){
                $data = [PSCustomObject]@{ 
                    ObjectId = $user.ObjectId
                    DisplayName = $user.displayname
                    UserPrincipalName = $user.UserPrincipalName
                    AzureADRole = $highprivrole
                    IsDirectorySynced = "UNKNOWN"
                }
                $highprivmembers += $data
            }
        }
    }
    foreach($userentry in $highprivmembers){
        if($userentry.IsDirectorySynced -like "UNKNOWN"){
            try{
                $currentuser = Get-AzureADUser -ObjectId $userentry.ObjectId
                $IsDirSynced = $currentuser.DirSyncEnabled
                If($IsDirSynced -like "True"){
                    $highprivmembers | ? { $_.ObjectId -like $userentry.ObjectId} |% { $_.IsDirectorySynced = "True" }
                }else{
                    $highprivmembers | ? { $_.ObjectId -like $userentry.ObjectId} |% { $_.IsDirectorySynced = "False" }
                }
            }catch{
                Write-Warning "There was an error when trying to query the user with Id $($userentry.ObjectId). A possible cause is that this is an enterprise app... Check manually!"
            }
        }
    }
    $affectedusers = $highprivmembers |? {$_.IsDirectorySynced -eq "True"}
    if($affectedusers.count -gt 0 ){
        $affectedusers | Export-Csv -NoTypeInformation "$env:Userprofile\Desktop\HighPrivUsers_Dirsynced.csv"
        Write-Warning "Found highly privileged users which are directory synced! List was exported to $($env:Userprofile)\Desktop\HighPrivUsers_Dirsynced.csv"
    }
}catch{
    Write-Warning "Unexpected error, script is aborted... Do you have enough privileges?"
}
