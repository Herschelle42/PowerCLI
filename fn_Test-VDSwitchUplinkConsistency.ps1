function Test-VDSwitchUplinkConsistency {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Name  # Expecting a cluster name

        # Optional: Filter a specific VDS if desired
        [string[]]$DistributedSwitch
    )

    process {
        $cluster = Get-Cluster -Name $Name -ErrorAction Stop
        $hosts = Get-VMHost -Location $cluster

        $results = foreach ($vmhost in $hosts) {
            $hostNics = Get-VMHostNetworkAdapter -VMHost $vmhost | Where-Object {
                $_.DistributedSwitch -ne $null -and
                ($null -eq $DistributedSwitch -or $_.DistributedSwitch.Name -in $DistributedSwitch)
            }

            $groupedByVDS = $hostNics | Group-Object { $_.DistributedSwitch.Name }

            foreach ($group in $groupedByVDS) {
                [PSCustomObject]@{
                    Cluster        = $cluster.Name
                    HostName       = $vmhost.Name
                    VDSwitch       = $group.Name
                    UplinkCount    = $group.Count
                    UplinkDevices  = ($group.Group.DeviceName -join ', ')
                }
            }
        }

        # Analyze consistency by VDS
        $results | Group-Object VDSwitch | ForEach-Object {
            $vdsGroup = $_.Group
            $expected = $vdsGroup[0].UplinkCount
            $inconsistent = $vdsGroup | Where-Object { $_.UplinkCount -ne $expected }

            [PSCustomObject]@{
                VDSwitch           = $_.Name
                ExpectedUplinks    = $expected
                Cluster            = $vdsGroup[0].Cluster
                HostCount          = $vdsGroup.Count
                Consistent         = ($inconsistent.Count -eq 0)
                InconsistentHosts  = ($inconsistent.HostName -join ', ')
            }
        }
    }
}
