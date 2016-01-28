<#
.Synopsis
  Reset VM resource configuration back to standard settings
.Description
  Changes VM the following resource configuration settings
  Disk IOPs Limit    : unlimited
  Disk Shares        : Normal
  CPU Limit          : unlimited
  CPU Reservation    : None
  CPU Shares         : Normal
  Mem Reserv all max : Off
  Mem Limit          : unlimited
  Mem Reservation    : None
  Mem Shares         : Normal
.References
  http://leetcloud.blogspot.com.au/2014/03/set-disk-iops-shares-shares-level-for.html
#>
$vm = Get-vm -Name "myvm"

#get current resource configuration
$vmconf = Get-VMResourceConfiguration -VM $vm

#Set all hard disks to Normal shares and remove all IOPs
Set-VMResourceConfiguration -Configuration $vmconf -Disk (Get-HardDisk -VM $vm) -DiskLimitIOPerSecond -1 -DiskSharesLevel Normal

#setting CPU resourcing back to Normal
Set-VMResourceConfiguration -Configuration $vmconf -CpuSharesLevel Normal -CpuLimitMhz $null -CpuReservationMhz 0

#Remove the reserve all guest memory setting
$vm_config = New-Object VMware.Vim.VirtualMachineConfigSpec
$vm_config.memoryReservationLockedToMax = $false
$vm.ExtensionData.ReconfigVM_task($vm_config)

#must remove the reserve all guest memory setting first (if set), else you will get an error attempting to run this command
#setting Memory resourcing back to Normal
Set-VMResourceConfiguration -Configuration $vmconf -MemSharesLevel Normal -MemLimitGB $null -MemReservationGB 0
