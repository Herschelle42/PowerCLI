function Get-VMHostResourceAssignment
{
<#
.Synopsis
    Report on each ESX host CPU and Memory as well as the total assigned VM CPU and Memory
.EXAMPLE
  PS> $vc = Get-VIServer -Server vcenter.lab.local
  PS> $vc | Get-VMHostResourceAssignment

  vCenter      Datacenter  Parent      VMHost     NumCPU     MemGB   VMCount     VMCPU   VMMemGB
  -------      ----------  ------      ------     ------     -----   -------     -----   -------
  vCenter1.... DC1         Cluster1    esx01...       16       192        18        36       144
  vCenter1.... DC1         Cluster1    esx04...       12        96        13        31       128
  horizon..... HorizonDC   Horizon     esx02...       16       192         9        16        64

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
        $vcenter,
        [Switch]$Anonymous
  )

  begin {
	$vmCPU = @{Name="vmCPU"; Expression={$_.Summary.Config.NumCpu} }
 	$vmMemGB = @{Name="vmMemGB"; Expression={ [Math]::Round($_.Summary.Config.MemorySizeMB/1KB, 0) } }
  } #end begin

  Process {

        #get a list of datacenter objects in the selected vCenter
        $dclist = Get-Datacenter -Server $vcenter | Sort-Object

        foreach ($dc in $dclist)
        {
            #get a list of all the hosts in the selected cluster
            $vmhostlist = Get-VMHost -Location $dc | Sort-Object
            foreach ($vmhost in $vmhostlist)
            {
                #get a list of all the VMs on the selected host
                [array]$vmlist = Get-View -Server $vcenter -ViewType VirtualMachine -SearchRoot $vmhost.id -Property Name, Summary.Config.NumCpu, Summary.Config.MemorySizeMB -filter @{"Config.Template"="false"}

			    $VMCount = 0
			    $TotalVMCPU = 0
			    $TotalVMMemGB = 0
		
			    #If there are no VMs then there are no calculations to do.
			    if ($vmlist)
			    {
				    $VMCount = $vmlist.Count
				    $TotalVMCPU = ($vmlist | Select $vmCPU | Measure-Object -Property vmCPU -SUM).Sum
				    $TotalVMMemGB = ($vmlist | Select $vmMemGB | Measure-Object -Property vmMemGB -SUM).Sum
			    } #end if vmcount
                
                #if anonymous switch has been used only report the Ids rather than Names for security purposes
                if ($Anonymous) {
                    #now create an object foreach VMHost
                    $hash = @{}
	                $hash.vCenter = $vcenter.InstanceUuid
	                $hash.Datacenter = $dc.Id
	                $hash.Parent = $vmhost.Parent.Id
	                $hash.VMHost = $vmhost.Id
	                $hash.NumCPU = $vmhost.NumCpu
	                $hash.MemGB = [Math]::Round($vmhost.MemoryTotalGB,0)
	                $hash.VMCount = $VMCount
	                $hash.VMCPU = $TotalVMCPU
	                $hash.VMMemGB = $TotalVMMemGB
	                $object = new-object -TypeName PSObject -property $hash
	                $object | Select vCenter, Datacenter, Parent, VMHost, NumCPU, MemGB, VMCount, VMCPU, VMMemGB
                } else {
                    #now create an object foreach VMHost
                    $hash = @{}
	                $hash.vCenter = $vcenter.name
	                $hash.Datacenter = $dc.name
	                $hash.Parent = $vmhost.Parent.Name
	                $hash.VMHost = $vmhost.name
	                $hash.NumCPU = $vmhost.NumCpu
	                $hash.MemGB = [Math]::Round($vmhost.MemoryTotalGB,0)
	                $hash.VMCount = $VMCount
	                $hash.VMCPU = $TotalVMCPU
	                $hash.VMMemGB = $TotalVMMemGB
	                $object = new-object -TypeName PSObject -property $hash
	                $object | Select vCenter, Datacenter, Parent, VMHost, NumCPU, MemGB, VMCount, VMCPU, VMMemGB
                }

            } #end foreach vmhost
        
        } #end foreach toplevel

  } # end process

} #end Function
