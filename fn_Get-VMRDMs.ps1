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


    } #end being block 

    Process
    {
      foreach ($item in $VMHostName)
      {
        Write-Verbose "Processing VMHost [$($item)]"

        #$vmhost = (Get-View -ViewType HostSystem -Property Name -Filter @{"Name"=$item}).Moref.Value
        #$vmhost = Get-View -ViewType HostSystem -Filter @{"Name"=$item}
        $vmhost = Get-View -ViewType HostSystem -Property Name, vm -Filter @{"Name"=$item}
        #$vmhost

        #$vmlist = Get-View -ViewType VirtualMachine -Property Name, Config.Hardware.Device, Runtime -Filter @{"Runtime.Host.Value"=$vmhost}
        [array]$vmlist = $vmhost | % { Get-View -ViewType VirtualMachine -SearchRoot $_.Moref -Filter @{"Config.Template"="false"} }
        #$vmlist | Select Name | Sort Name

        if ($vmlist)
        {
            foreach ($vm in $vmlist)
            {
                #DiskTypes : rawVirtual, rawPhysical, flat, unknown
                #$vm.Config.Hardware.Device[10].gettype().Name = VirtualDisk
                
                #Get all Virtual Disk devices that have a Compatibility Mode. This will return both physicalMode and virtualMode.
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

