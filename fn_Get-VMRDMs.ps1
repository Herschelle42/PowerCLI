<#
.Synopsis
   Get VMs with RDMs
.DESCRIPTION
   Given a VMHost or list of VMHosts, report the VMs that have RDMs.
.EXAMPLE
   Example of how to use this cmdlet
.Notes
  Author:   Clint Fritz
  Futures:  Add ability to do Cluster, Datastore, DC
  Reference:
  http://blog.vmpros.nl/2011/08/03/vmware-list-all-rdm-disks-in-virtual-machines-via-powercli/
#>
function Get-VMRDMs
{
    [CmdletBinding(DefaultParameterSetName='Parameter Set 1', 
                  SupportsShouldProcess=$true, 
                  PositionalBinding=$false,
                  ConfirmImpact='Medium')]
    Param
    (
        # Name of Virtual Machine to export
        [Parameter(Mandatory=$true, 
                   ValueFromPipeline=$true,
                   ValueFromPipelineByPropertyName=$true, 
                   Position=0)]
        [ValidateNotNull()]
        [ValidateNotNullOrEmpty()]
        [string[]]$VMHostName

    )  #end param block 

    Begin
    {
      #Add test for PowerCLI snapins and or modules loaded

      #add test for PowerCLI version. 5.1 + has CapacityInKB where 5.0 does not. It has Capacity (in bytes)?

      #add test for vCenter connectivity

    } #end being block 

    Process
    {
      foreach ($item in $VMHostName)
      {
        Write-Verbose "Processing VMHost [$($item)]"

        $vmhost = Get-View -ViewType HostSystem -Property Name, vm -Filter @{"Name"=$item}

        #$vmlist = Get-View -ViewType VirtualMachine -Property Name, Config.Hardware.Device, Runtime -Filter @{"Runtime.Host.Value"=$vmhost}
        [array]$vmlist = $vmhost | % { Get-View -ViewType VirtualMachine -SearchRoot $_.Moref -Filter @{"Config.Template"="false"} }

        if ($vmlist)
        {
            foreach ($vm in $vmlist)
            {
                #DiskTypes : rawVirtual, rawPhysical, flat, unknown
                #Get all Virtual Disk devices that have a Compatibility Mode. e.g. physicalMode and virtualMode.
                #Normal VMDK\HDD will not have any value in Compatibility Mode.
                foreach ($dev in $vm.Config.Hardware.Device | ? { $_.gettype().name -eq "VirtualDisk" -and $_.Backing.CompatibilityMode } )
                {
                  $properties = [Ordered]@{
                    'VMName'=$vm.Name; 
                    'VMHost'=$vmhost.Name;
                    'HDDName'=$dev.DeviceInfo.Label;
                    'HDDMode'=$dev.Backing.CompatibilityMode;
                    'HDDCapacityKB'=$dev.CapacityinKB
                  } #end properties
                  $object = New-Object –TypeName PSObject –Prop $properties 
                  Write-Output $object                
                
                } #end foreach Devices

            } #end foreach vmlist
        } else {
          Write-Verbose "No VMs on this host have RDMs"
        } #end if vmlist
      } #end foreach VMHost


    } #end process block 

    End
    {
      Write-Verbose "End"
    } #end End Block

} #end function

Get-VMRDMs -VMHostName "devesxi1.corp.local","prodesxi1.corp.local" -Verbose

<#

VMName        : S1SQL1
VMHost        : devesxi1.corp.local
HDDName       : Hard disk 3
HDDMode       : physicalMode
HDDCapacityKB : 20971520


$report = @()
$vms = Get-VM | Get-View
foreach($vm in $vms){
     foreach($dev in $vm.Config.Hardware.Device){
          if(($dev.gettype()).Name -eq "VirtualDisk"){
               if(($dev.Backing.CompatibilityMode -eq "physicalMode") -or
               ($dev.Backing.CompatibilityMode -eq "virtualMode")){
                    $row = "" | select VMName, VMHost, HDDeviceName, HDFileName, HDMode, HDsize, HDDisplayName
                    $row.VMName = $vm.Name
                    $esx = Get-View $vm.Runtime.Host
                    $row.VMHost = ($esx).Name
                    $row.HDDeviceName = $dev.Backing.DeviceName
                    $row.HDFileName = $dev.Backing.FileName
                    $row.HDMode = $dev.Backing.CompatibilityMode
                    $row.HDSize = $dev.CapacityInKB
                    $row.HDDisplayName = ($esx.Config.StorageDevice.ScsiLun | where {$_.Uuid -eq $dev.Backing.LunUuid}).DisplayName
                    $report += $row
               }
          }
     }
}
$report
#>

