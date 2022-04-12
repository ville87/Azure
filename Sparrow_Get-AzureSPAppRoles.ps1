# Parts taken from https://github.com/cisagov/Sparrow/blob/develop/Sparrow.ps1
[string] $Delimiter = "," # Change this delimiter for localization support of CSV import into Excel
[string] $ExportDir = (Join-Path ([Environment]::GetFolderPath("Desktop")) 'ExportDir') # Change path here if you don't want the generated CSV to be stored on the current users desktop
[string] $AzureEnvironment = "AzureCloud" # Change environment if this is not the one you are in... (for CH it should be usually this)
$ModuleArray = @("AzureAD")

ForEach ($ReqModule in $ModuleArray){
    If ($null -eq (Get-Module $ReqModule -ListAvailable -ErrorAction SilentlyContinue)){
        Write-Verbose "Required module, $ReqModule, is not installed on the system."
        Write-Verbose "Installing $ReqModule from default repository"
        Install-Module -Name $ReqModule -Force
        Write-Verbose "Importing $ReqModule"
        Import-Module -Name $ReqModule
    } ElseIf ($null -eq (Get-Module $ReqModule -ErrorAction SilentlyContinue)){
        Write-Verbose "Importing $ReqModule"
        Import-Module -Name $ReqModule
    }
}
Function Get-AzureSPAppRoles{
    [cmdletbinding()]Param(
        [Parameter(Mandatory=$true)]
        [string] $AzureEnvironment,
        [Parameter(Mandatory=$true)]
        [string] $ExportDir,
        [Parameter(Mandatory=$true)]
        [string] $Delimiter
        )

    #Retrieve all service principals that are applications
    $SPArr = Get-AzureADServicePrincipal -All $true | Where-Object {$_.ServicePrincipalType -eq "Application"}

    #Retrieve all service principals that have a display name of Microsoft Graph
    $GraphSP = Get-AzureADServicePrincipal -All $true | Where-Object {$_.DisplayName -eq "Microsoft Graph"}

    $GraphAppRoles = $GraphSP.AppRoles | Select-Object -Property AllowedMemberTypes, Id, Value

    $AppRolesArr = @()
    Foreach ($SP in $SPArr) {
        $GraphResource = Get-AzureADServiceAppRoleAssignedTo -ObjectId $SP.ObjectId | Where-Object {$_.ResourceDisplayName -eq "Microsoft Graph"}
        ForEach ($GraphObj in $GraphResource){
            For ($i=0; $i -lt $GraphAppRoles.Count; $i++){
                if ($GraphAppRoles[$i].Id -eq $GraphObj.Id) {
                    $ListProps = [ordered]@{
                        ApplicationDisplayName = $GraphObj.PrincipalDisplayName
                        ClientID = $GraphObj.PrincipalId
                        Value = $GraphAppRoles[$i].Value
                    }
                }
            }
            $ListObj = New-Object -TypeName PSObject -Property $ListProps
            $AppRolesArr += $ListObj 
            }
        }
    #If you want to change the default export directory, please change the $ExportDir value.
    #Otherwise, the default export is the user's home directory, Desktop folder, and ExportDir folder.
    #You can change the name of the CSV as well, the default name is "ApplicationGraphPermissions"
    $AppRolesArr | Export-Csv $ExportDir\ApplicationGraphPermissions.csv -NoTypeInformation -Delimiter $Delimiter
}

# Login 
Connect-AzureAD -AzureEnvironmentName $AzureEnvironment
# create output dir
If (!(Test-Path $ExportDir)){
    New-Item -Path $ExportDir -ItemType "Directory" -Force
}
# Run the function
Get-AzureSPAppRoles -AzureEnvironment $AzureEnvironment -ExportDir $ExportDir -Verbose -Delimiter $Delimiter
