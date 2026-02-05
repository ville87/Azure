<#
Collect MFA status for all users
First connect in powershell console with: Connect-MgGraph -Scopes "UserAuthenticationMethod.Read.All,User.Read.All"
#>

#Get all Azure users, except EXT users
$users = Get-MgUser -All | Where-Object { $_.UserPrincipalName -notmatch "#EXT" }

$results=@();
Write-Host  "`nRetreived $($users.Count) users";

foreach ($user in $users) {
  Write-Host  "`n$($user.UserPrincipalName)";
  $CustomPSObject = [PSCustomObject]@{
      user               = "-"
      MFAstatus          = "-"
      email              = "False"
      fido2              = "False"
      fido2model         = "n/a"
      app                = "False"
      MSauthApp          = "False"
      MSauthAppDeviceTag = "n/a"
      MSAuthAppDisplayName = "n/a"
      password           = "False"
      phone              = "False"
      softwareoath       = "False"
      tempaccess         = "False"
      hellobusiness      = "False"
  }

  $MFAData = Get-MgUserAuthenticationMethod -UserId $user.UserPrincipalName

  $CustomPSObject.user = $user.UserPrincipalName;
      ForEach ($method in $MFAData) {
      
          Switch ($method.AdditionalProperties["@odata.type"]) {
            "#microsoft.graph.emailAuthenticationMethod"  { 
              $CustomPSObject.email = $true 
              $CustomPSObject.MFAstatus = "Enabled"
            }    
            "#microsoft.graph.microsoftAuthenticatorAuthenticationMethod"  { 
              $CustomPSObject.app = $true 
              $CustomPSObject.MFAstatus = "Enabled"
            }    
            "#microsoft.graph.passwordAuthenticationMethod"                {              
                  $CustomPSObject.password = $true 
                  if($CustomPSObject.MFAstatus -ne "Enabled")
                  {
                      $CustomPSObject.MFAstatus = "Disabled"
                  }                
            }     
            "#microsoft.graph.phoneAuthenticationMethod"  { 
              $CustomPSObject.phone = $true 
              $CustomPSObject.MFAstatus = "Enabled"
            }   
              "#microsoft.graph.softwareOathAuthenticationMethod"  { 
              $CustomPSObject.softwareoath = $true 
              $CustomPSObject.MFAstatus = "Enabled"
            }           
              "#microsoft.graph.temporaryAccessPassAuthenticationMethod"  { 
              $CustomPSObject.tempaccess = $true 
              $CustomPSObject.MFAstatus = "Enabled"
            }           
              "#microsoft.graph.windowsHelloForBusinessAuthenticationMethod"  { 
              $CustomPSObject.hellobusiness = $true 
              $CustomPSObject.MFAstatus = "Enabled"
            }

        }
        # Check MS Authenticator app separately (different MgGraph cmdlet)
        $MSAuthmethod = Get-MgUserAuthenticationMicrosoftAuthenticatorMethod -UserId $user.UserPrincipalName
        if($MSAuthmethod -eq $null){
          $CustomPSObject.MSauthApp = "False"
        }else{
          $CustomPSObject.MSauthApp = $true 
          $CustomPSObject.MSauthAppDeviceTag = $($MSAuthmethod.DeviceTag -join ';')
          $CustomPSObject.MSAuthAppDisplayName = $($MSAuthmethod.DisplayName -join ';')
          $CustomPSObject.MFAstatus = "Enabled"
        }

        # Check FIDO separately (different MgGraph cmdlet)
        $Fido2Method = Get-MgUserAuthenticationFido2Method -UserId $user.UserPrincipalName
        if($fido2method -eq $null){
          $CustomPSObject.fido2 = "False"
        }else{
          $CustomPSObject.fido2 = $true 
          $CustomPSObject.fido2model = $($fido2method.Model -join ';')
          $CustomPSObject.MFAstatus = "Enabled"
        }
      }

  $results+= $CustomPSObject;

}

$results | Export-Csv .\mfa_results.csv -NoTypeInformation
