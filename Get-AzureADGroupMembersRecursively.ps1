function Get-AadGroupMembers {
    param (
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)][string]$ObjectID
    )
    $output=@()

    try {
        $object = Get-AzureADObjectByObjectId -ObjectId $objectid
    }catch{
        Write-Error "unexpected error"
        return
    }

    if ($object.ObjectType -ne "Group")
    {
        Write-Error "Object is not a group"    
    }

    $members = Get-AzureADGroupMember -ObjectId $ObjectID -all $true
    foreach ($member in $members)
    {
            if ($member.ObjectType -ne 'Group')
            {
                $output += $member
            } 
            else
            {
                $output += get-AadGroupMembers $member.ObjectId
            }
    }
    $output | Select-Object -Unique
}

# get groups you want to check
$MFAExclGroups = Get-AzureADGroup -SearchString "MFA excluded group"
$MFAExclGroupMembers = @()
foreach($MFAExclGroup in $MFAExclGroups){
    $MFAExclGroupMembers += get-AadGroupMembers $MFAExclGroup.ObjectId
}
