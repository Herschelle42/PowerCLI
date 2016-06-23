function Get-VMLocationDetails
{
<#
.Synopsis
    Report on each VMs location (Host and Clusters) within vCenter
.EXAMPLE
  PS> $vc = Get-VIServer -Server vcenter.lab.local
  PS> $vc | Get-VMLocationDetails

  vCenter            Datacenter   Cluster   VMHost           VMName              
  -------            ----------   -------   ------           ------              
  vcenter.lab.local  DC1          dc1-cl1   esx01.lab.local  vm1
  vcenter.lab.local  DC1          dc1-cl1   esx01.lab.local  vm2
  vcenter.lab.local  DC2          dc2-cl1   esx04.lab.local  vm3

.NOTES
  Author:   Clint Fritz
  Version:  0.1
  Date:     2016-06-23

#>
  [CmdletBinding()]
  param(
        [Parameter(
            Mandatory=$true,
            ValueFromPipeline=$true,
            HelpMessage="vcenter object"
        )]
        [VMware.VimAutomation.ViCore.Impl.V1.VIServerImpl]
        $vcenter
  )

  Process {

        #Write-Output "vCenter:  $($vcenter.Name)"

        #get a list of datacenter objects in the selected vCenter
        $dclist = Get-Datacenter -Server $vcenter | Sort-Object

        foreach ($dc in $dclist)
        {
            #get a list of all the clusters in the selected datacenter
            $cllist =  Get-Cluster -Location $dc | Sort-Object
            foreach ($cluster in $cllist)
            {
                #get a list of all the hosts in the selected cluster
                $vmhostlist = Get-VMHost -Location $cluster | Sort-Object
                foreach ($vmhost in $vmhostlist)
                {
                    #get a list of all the VMs on the selected host
                    $vmlist = Get-VM -Location $vmhost | Sort-Object
                    foreach ($vm in $vmlist)
                    {
                    
                        #now create an object foreach VM
                        $hash = @{}
	                    $hash.vCenter = $vcenter.name
	                    $hash.Datacenter = $dc.name
	                    $hash.Cluster = $cluster.name
	                    $hash.VMHost = $vmhost.name
	                    $hash.VMName = $vm.name
	                    $object = new-object -TypeName PSObject -property $hash
	                    $object | Select vCenter, Datacenter, Cluster, VMHost, VMName

                    } #end foreach vm

                } #end foreach vmhost

            } #end foreach cluster
        
        } #end foreach toplevel

  } # end process

} #end Function
