function Test-VDSwitchUplinkConsistency {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipelineByPropertyName)]
        [string]$Name
    )

    process {
        $cluster = Get-Cluster -Name $Name -ErrorAction Stop
        $hosts = Get-VMHost -Location $cluster

        $uplinkInfo = foreach ($vmhost in $hosts) {
            $view = Get-View -Id $vmhost.Id

            foreach ($proxySwitch in $view.Config.Network.ProxySwitch) {
                $vdsName = $proxySwitch.DvsName
                $uplinks = $proxySwitch.Spec.Backing.PnicSpec | ForEach-Object { $_.PnicDevice }

                [PSCustomObject]@{
                    Cluster       = $cluster.Name
                    HostName      = $vmhost.Name
                    VDSwitch      = $vdsName
                    UplinkCount   = $uplinks.Count
                    UplinkDevices = $uplinks -join ', '
                }
            }
        }

        # Analyze consistency per VDS
        $uplinkInfo | Group-Object VDSwitch | ForEach-Object {
            $group = $_.Group
            $expected = $group[0].UplinkCount
            $inconsistent = $group | Where-Object { $_.UplinkCount -ne $expected }

            [PSCustomObject]@{
                VDSwitch           = $_.Name
                Cluster            = $group[0].Cluster
                ExpectedUplinks    = $expected
                HostCount          = $group.Count
                Consistent         = ($inconsistent.Count -eq 0)
                InconsistentHosts  = ($inconsistent.HostName -join ', ')
            }
        }
    }
}
