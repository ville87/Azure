param(
    [Parameter(Mandatory = $true)]$TenantID
)
 
$ErrorActionPreference = "Stop"
Connect-AzAccount -TenantId $TenantID
 
#Get list of all subscriptions in specific tenant id
$subscriptionsArray = Get-AzSubscription -tenantID $TenantID | Select-Object Name, ID
 
#Create arrays for missing NSG and ASG
$vmsMissingNSG = @()
$vmsMissingASG = @()
 
#Iterate across all subscriptions found for specific tenant ID
foreach ($subscription in $subscriptionsArray) {
    Write-Output "Working on subscription $($subscription.Name)"
    Select-AzSubscription -SubscriptionId $subscription.Id | Out-Null
    # Gather information about all virtual machines in specific subscription
    $vmsArray = Get-AzVM | Select-Object ResourceGroupName, Name, NetworkProfile
     
    # Proceed with furhter part of the script in case that there is at least one vm created
    if ($vmsArray) {
        foreach ($vm in $vmsArray) {
            # Gather information about network interfaces configuration like ID, resource group, subnet etc.
            $vmNetworkInterfacesIdArray = $vm.NetworkProfile.networkInterfaces.id
            # Iterate across all nics attached to VM
            foreach ($vmNetworkInterfaceId in $vmNetworkInterfacesIdArray) {
                $vmNetworkInterfaceObject = Get-AzResource -id $vmNetworkInterfaceId | Get-AzNetworkInterface
                $vmNetworkInterfaceSubnet = $vmNetworkInterfaceObject.IpConfigurations.subnet.Id
                # Check which NSGs and ASGs are assigned to network interface
                $vmNsgAssigned = $vmNetworkInterfaceObject.NetworkSecurityGroupText
                $vmAsgAssigned = $vmNetworkInterfaceObject.IpConfigurations.ApplicationSecurityGroupsText
             
                # Check network name and subnet name for which nic is connected
                $vmNetworkInterfaceVnetName = $vmNetworkInterfaceSubnet.Split("/")[8] 
                $vmNetworkInterfaceSubnetName = $vmNetworkInterfaceSubnet.Split("/")[-1] 
                $vmVnetResourceGroup = $vmNetworkInterfaceSubnet.Split("/")[4]
                $vnetObject = Get-AzVirtualNetwork -Name $vmNetworkInterfaceVnetName -ResourceGroupName $vmVnetResourceGroup
                $subnetObject = Get-AzVirtualNetworkSubnetConfig -Name $vmNetworkInterfaceSubnetName -VirtualNetwork $vnetObject
             
                # If there is no NSG assigned to NIC and subnet attached to the nic doesn't have NSG assigned as well add virtual machine to array with missing NSGs
                if ($vmNsgAssigned -eq "null" -and !$subnetObject.NetworkSecurityGroup.Id) {
 
                    $vmObject = New-Object PSObject -Property ([ordered]@{ 
                            "Virtual Machine Name" = $vm.Name
                            "Resource Group Name"  = $vm.ResourceGroupName
                            "Subscription"         = $subscription.Name
                            "Subnet"               = $vmNetworkInterfaceSubnetName
                            "Virtual Network"      = $vmNetworkInterfaceVnetName
                        })
                  
                    $vmsMissingNSG += $vmObject
                }
                # If there is nsg assgined to virtual machine either on nic or subnet level 
                else {
                    # But there is no ASGs assigned add virtual machine to missing ASGs array
                    if ($null -eq $vmAsgAssigned) {
                        $vmObject = New-Object PSObject -Property ([ordered]@{ 
                                "Virtual Machine Name" = $vm.Name
                                "Resource Group Name"  = $vm.ResourceGroupName
                                "Subscription"         = $subscription.Name
                                "Subnet"               = $vmNetworkInterfaceSubnetName
                                "Virtual Network"      = $vmNetworkInterfaceVnetName
                            })
                        $vmsMissingASG += $vmObject
                    }
                }
            }
        }
    }
    else {
        Write-Output "No virtual machines found in subscription $($subscription.Name)"
    }
    Write-Output "----------------------------"
}
 
Write-Output "Virtual machines with missing NSG: $($vmsMissingNSG.Count)"
$vmsMissingNSG
 
Write-Output "Virtual machines with missing ASG: $($vmsMissingASG.Count)"
$vmsMissingASG
