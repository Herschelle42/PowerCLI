function Get-StandardSwitchVMReport {
<#
.DESCRIPTION
  Creates a list of standard switch port groups with VMs attached.
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory, ValueFromPipeline)]
        [VMware.VimAutomation.ViCore.Impl.V1.Inventory.VMHostImpl[]]$VMHost
    )

    process {
        Write-Verbose "Processing VMHost: $($VMHost.Name)" -Verbose
        # Get vSwitches on host
        $vSwitches = Get-VirtualSwitch -VMHost $VMHost -Standard
        $vmList = Get-VM -Location $VMHost
        $vmkAdapters = Get-VMHostNetworkAdapter -VMHost $VMHost -VMKernel

        foreach ($vSwitch in $vSwitches) {
            # Get Port Groups on vSwitch
            $portGroups = Get-VirtualPortGroup -VirtualSwitch $vSwitch

            foreach ($pg in $portGroups) {
                # Get all VMs connected to this Port Group
                $connectedVMs = $vmList | ForEach-Object {
                    $vm = $_
                    $adapters = Get-NetworkAdapter -VM $vm | Where-Object {
                        $_.NetworkName -eq $pg.Name
                    }
                    if ($adapters) { $vm }
                }

                $vmkPorts = $vmkAdapters | Where-Object { $_.PortGroupName -eq $pg.Name }

                [PSCustomObject]@{
                    Cluster       = $VMHost.Parent
                    Host          = $VMHost.Name
                    vSwitch       = $vSwitch.Name
                    PortGroup     = $pg.Name
                    Nic           = ($vSwitch.Nic -join ', ')
                    VMKernelPorts = ($vmkPorts.Name -join ', ')
                    ConnectedVMs  = ($connectedVMs.Name -join ', ')
                }
            }
        }
    }
}
