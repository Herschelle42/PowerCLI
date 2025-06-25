function Get-StandardSwitchVMReport {
<#
.DESCRIPTION
  Creates a list of standard switch port groups with VMs attached.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl[]]$VMHosts
    )

    $report = @()

    foreach ($vmhost in $VMHosts) {
        # Get vSwitches on host
        $vSwitches = Get-VirtualSwitch -VMHost $vmhost -Standard

        foreach ($vSwitch in $vSwitches) {
            # Get Port Groups on vSwitch
            $portGroups = Get-VirtualPortGroup -VirtualSwitch $vSwitch

            foreach ($pg in $portGroups) {
                # Get all VMs connected to this Port Group
                $connectedVMs = Get-VM -Location $vmhost | ForEach-Object {
                    $vm = $_
                    $adapters = Get-NetworkAdapter -VM $vm | Where-Object {
                        $_.NetworkName -eq $pg.Name
                    }
                    if ($adapters) { $vm }
                }

                $report += [PSCustomObject]@{
                    HostName        = $vmhost.Name
                    vSwitch         = $vSwitch.Name
                    PortGroup       = $pg.Name
                    ConnectedVMs    = ($connectedVMs.Name -join ', ')
                }
            }
        }
    }

    return $report
}
