<#
.Synopsis
   Tests whether the given VM has one or more RDMs 
.DESCRIPTION
   This is a simple True and False output.
.Notes
   Author: Clint Fritz
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Test-RDMConnected
{
    [CmdletBinding()]
    Param
    (
        # VM to test
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $VM
    )

    Begin
    {
      #add test for vCenter connectivity

      #add test for PowerCLI version?

    } #end being block

    Process
    {
      Write-Verbose "Process each VM"
      foreach ($item in $vm){
        Write-Verbose "Processing VM : [$($item)]"
        [array]$vmview = Get-View -ViewType VirtualMachine -Filter @{"Name"=$item} -Property Name, Config.Hardware
        if ($vmview.Count -eq 1)
        {
          Write-Verbose "Test for RDM"

        } elseif ($vmview.Count -gt 1) {
          Write-Verbose "[WARNING] More than one VM found with the same name."
          foreach ($dev in $vm.Config.Hardware.Device | ? { $_.gettype().name -eq "VirtualDisk" -and $_.Backing.CompatibilityMode } )
            {
              Write-Output $true
            } #end properties
            $object = New-Object –TypeName PSObject –Prop $properties 
            Write-Output $object                

        } else {
          Write-Verbose "VM not found"
        } #end if vmview.count

      } #end foreach vm
    } #end process block

    End
    {
      Write-Verbose "End"
    } #end 
} #end function 

Test-RDMConnected -VM S1SQL1 -Verbose
Test-RDMConnected -VM infdevms1 -Verbose

