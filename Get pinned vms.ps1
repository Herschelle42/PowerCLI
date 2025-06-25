<#
.DESCRIPTION
  Attempting to get a list of VMs that are pinned to a host.
.NOTES
  Get-DrsRule is now deprecated. need to update to use Get-DrsVMHostRule
#>
#VM/host affinity rules
$VmHostAffinityList = Get-Cluster | Get-DrsRule -Type VMHostAffinity
#$VmHostAffinityList = Get-Cluster | Get-DrsVMHostRule | ? { $_.Enabled -eq $true }
$VmHostAffinityList.count

$reportVMHostRules = foreach($rule in $VmHostAffinityList) {
    [PSCustomObject]@{
        Name = $rule.Name
        Enabled = $rule.Enabled
        Mandatory = $rule.ExtensionData.Mandatory
        Cluster = $rule.Cluster
        VMNames = &{ ($rule.VMIds | % { get-view -Id $_ -Property Name | Select-Object -ExpandProperty Name })  -join ',' }
        HostNames = & { ($rule.AffineHostIds | % { get-view -Id VirtualMachine-vm-2113647 -Property Name | Select-Object -ExpandProperty Name } ) -join ',' }
    }
}
$reportVMHostRules | ft -AutoSize
