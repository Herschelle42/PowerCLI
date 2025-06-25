#count physical nics on hosts
Get-VMHost | ForEach-Object { 
    $vmhost = $_
    $uplinks = Get-VMHostNetworkAdapter -VMHost $vmhost -Physical
    [PSCustomObject]@{
        Name     = $_.Name
        NICCount = $uplinks.count

    }
}
