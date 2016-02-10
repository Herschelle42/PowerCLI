$cluster = "Test"

#Report on RDMs and whether they are Perennially Reserved or not
foreach ($vc in $global:DefaultVIServers)
{
    $cllist = Get-Cluster -Name "*$cluster*" -Server $vc
    foreach ($cluster in $cllist)
    {
        Write-Verbose "get a list of the naas which are RDMs in cluster [$($cluster.name)]"
        $naalist = Get-VM -Location $cluster | Get-HardDisk -DiskType RawPhysical | Select -ExpandProperty ScsiCanonicalName -Unique

        Write-Verbose "cycle through each host"
        foreach ($vmhost in ($vmhostlist = Get-VMHost -Location $cluster) )
        {
            Write-Verbose "Get ESX Cli object for host [$($vmhost.name)]"
            $esxcli = Get-EsxCli -VMHost $vmhost
            foreach ($naa in $naalist)
            {
                #PS 2.0 does not support the [Ordered] type. Was introduced in PS 3.0 CTP1
                if ($PSVersionTable.PSVersion.Major -gt 2)
                {
                    $properties = [Ordered]@{
                        'vCenter'=$vc.Name;
                        'VMHost'=$vmHost.Name;
                        'naa'=$naa;
                        'PerennialReserved'=$esxcli.storage.core.device.list($naa).isperenniallyReserved;
                        'SizeGB'=[Math]::Round($esxcli.storage.core.device.list($naa).size/1KB,0)
                    }
                    $object = New-Object -TypeName PSObject -Property $properties
                    Write-Output $object 
                } else {
                    $properties = @{
                        'vCenter'=$vc.Name;
                        'VMHost'=$vmHost.Name;
                        'naa'=$naa;
                        'PerennialReserved'=$esxcli.storage.core.device.list($naa).isperenniallyReserved;
                        'SizeGB'=[Math]::Round($esxcli.storage.core.device.list($naa).size/1KB,0)
                    }
                    $object = New-Object -TypeName PSObject -Property $properties
                    Write-Output $object | Select vCenter, VMHost, naa, PerennialReserved, SizeGB
                } #end if PSVersionTable

            } #end foreach naalist

        } #end foreach vmhost

    } #end foreach cllist

} #end foreach defaultVIServers

#Change RDMs to Perennially Reserved, if they are not already
foreach ($vc in $global:DefaultVIServers)
{
    $cllist = Get-Cluster -Name "*$cluster*" -Server $vc
    foreach ($cluster in $cllist)
    {
        Write-Output "get a list of the naas which are RDMs in cluster [$($cluster.name)]"
        $naalist = Get-VM -Location $cluster | Get-HardDisk -DiskType RawPhysical | Select -ExpandProperty ScsiCanonicalName -Unique

        Write-Output "cycle through each host"
        foreach ($vmhost in ($vmhostlist = Get-VMHost -Location $cluster) )
        {
            Write-Output "Get ESX Cli object for host [$($vmhost.name)]"
            $esxcli = Get-EsxCli -VMHost $vmhost
            foreach ($naa in $naalist)
            {
                #Set reservation if not already set, otherwise move on
                if ( ($esxcli.storage.core.device.list($naa).isperenniallyReserved) -eq "false" )
                {
                    Write-Output "Setting Perennial Reservation on [$($naa)]"
                    $esxcli.storage.core.device.setconfig($false, $naa, $true)
                } else {
                    Write-Output "[$($naa)] already reserved."
                } #end if perenniallyreserver

            } #end foreach naalist

        } #end foreach vmhost

    } #end foreach cllist

} #end foreach defaultVIServers
