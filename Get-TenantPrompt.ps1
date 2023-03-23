<# PowerShell prompt for choosing tenant from list
Example output:
Choose the tenant to sent messages to
[0] 0 Tenant ABC  [1] 1 Some Other Tenant XYZ  [?] Help (default is "0"):

# d3590ed6-52b3-4102-aeff-aad2292ab01c --> Microsoft Office ClientId
#>
$choises="0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ!""#%&/()=?*+-_"
$AccessToken = Get-AccessTokenFromCache -AccessToken $AccessToken -Resource "https://management.core.windows.net/" -ClientId "d3590ed6-52b3-4102-aeff-aad2292ab01c"
$Tenant = Get-AADIntTenantID -UserName $Recipients[0]
$tenants = Get-AzureTenants -AccessToken $AccessToken
$tenantNames = $tenants | select -ExpandProperty Name

# Prompt for tenant choice if more than one
if($tenantNames.count -gt 1)
{
    $options = [System.Management.Automation.Host.ChoiceDescription[]]@()
    for($p=0; $p -lt $tenantNames.count; $p++)
    {
        $options += New-Object System.Management.Automation.Host.ChoiceDescription "&$($choises[$p % $choises.Length]) $($tenantNames[$p])"
    }
    $opt = $host.UI.PromptForChoice("Choose the tenant","Choose the tenant to sent messages to",$options,0)
}
else
{
    $opt=0
}