# This script can be used to create an amount of users in Entra ID (without role assignments / privileges)
# Number of users you want to create:
[int]$usercount = 100

# Specify your Entra ID tenant domain here
$tenantDomain = "yourm365domain.com"

# login
Write-Host "Connecting to the Entra ID tenant now, please login with a Global Admin, because you will be requested to grant an MS Graph Permission scope!"
try {
    Connect-MgGraph -Scopes "User.ReadWrite.All"
    if((Get-MgContext).Scopes -notcontains "User.ReadWrite.All"){
        Write-Warning "Something went wrong, current MgGraph context does not contain scope 'User.ReadWrite.All'! Cannot continue..."
        Exit 5
    }
}
catch {
    Write-Warning "Unknown error occured during MgGraph connect..."
    Exit 6
}

# generate user names
$userlist = @()
for($i=1;$i -le $usercount;$i++){
    $percent = [math]::Round(($i / $usercount) * 100, 2)
    Write-Progress -Activity "Getting random users..." -Status "$i / $usercount" -PercentComplete $percent
    $response = Invoke-RestMethod -Uri "https://randomuser.me/api/" -UseBasicParsing -Method Get
    $name = ($response.results.email -split ("@"))[0]
    $userlist += $name
    Start-Sleep -Seconds 1
}
if(($userlist | Measure-Object).count -lt $usercount){
    Write-Warning "Something went wrong when generating random users! Script will abort..."
    Exit 7
}else{
    $userlist | out-file .\randomuserlist.txt
    Write-Host "Got the list of $($usercount) users. List exported to: .\randomuserlist.txt"
    pause
}
Write-Progress -Activity "Getting random users..." -Completed

# Test User Creation for Entra ID 
$UserExport = @()
# Create the users in Entra ID 
foreach($userentry in $userlist){
    try{
        # Define user variables
        $displayName = "zzzScriptGenerated $($userentry.split('.')[0]) $($userentry.split('.')[1])"
        $mailNickname = "$($userentry.split('.')[0])$($userentry.split('.')[1])"
        $UserUPN = "$userentry@$tenantDomain"
        # PowerShell Core does not support this :(
        # $PWString = [System.Web.Security.Membership]::GeneratePassword(14,1)
        $PWString = -join ((33..126) * 120 | Get-Random -Count 24 | ForEach-Object { [char]$_ })
        $PasswordProfile = @{
            Password = $PWString
        }
        Write-Host "Creating user $UserUPN..."

        # Create the user via Microsoft Graph
        New-MgUser -AccountEnabled -DisplayName $displayName -UserPrincipalName $UserUPN -MailNickname $mailNickname -PasswordProfile $PasswordProfile

        # Store user information in a custom object
        $data = [PSCustomObject]@{
            UserUPN = $UserUPN
            UserPW = $PWString
        }
        $UserExport += $data
    }catch{
        Write-Host "Could not create Entra ID user. Error message:`r`n$($error[0].Exception)`r`nTerminating script..."
        $UserExport | Export-Csv -NoTypeInformation -path ".\status-createdusers.csv"
        Start-Sleep -Seconds 1
        Write-Host "Last status of created users was exported to .\status-createdusers.csv"
        Exit 8
    }
}
$exportfile = ".\exportusers.csv"
$UserExport | Export-Csv -NoTypeInformation -Path $exportfile
Write-Host "Script done. Exported user list to $exportfile"
