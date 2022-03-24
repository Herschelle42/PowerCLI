
$vCenterName = "vcsa.corp.local"
$credvCenter = Get-Credential -Message "vCenter Credentials required"
$vmName = "win10-01"
$osAccountName = "tempLocal"
$credOSAccount = Get-Credential -Message "VM OS Account credentials required."


#The source script to be copied to the VM
$sourceScript = "C:\Data\Scripts\myscript.ps1"
#The location on the destination VM
$destinationScript = "C:\Temp\myCopiedScript.ps1"


$vCenter = Connect-VIServer -Server $vCenterName -Credential $credvCenter
$vm = get-vm -Name $vmName


#If Guestname is FQDN we need to split the domain off.
#Do this incase the Guest OS Name is different to the vmName.
$vmGuestHostname = $vm.ExtensionData.Summary.Guest.HostName.Split(".")[0]
Write-Output "[INFO] $(Get-Date) VM Guest hostname: $($vmGuestHostname)"

#Set Credential to use to authenticate to the Windows OS of the VM
$guestCredential = New-Object System.Management.Automation.PSCredential "$($vmGuestHostname)\$($osAccountName)", $credOSAccount.Password

$scriptType = "Powershell"


#have to add the New Line join because the GetBytes() method expects a single string!
$fileData = (Get-Content -Path $sourceScript -Encoding Ascii) -join [Environment]::NewLine


$encodedData = [convert]::ToBase64String([System.Text.Encoding]::ASCII.GetBytes($fileData))

#Cannot be a hereString for this to work. But we do not need that for this.
$scriptText = "[System.Text.Encoding]::ASCII.GetString([System.Convert]::FromBase64String('$encodedData')) | out-file -FilePath $destinationScript -Encoding ASCII"

Invoke-VMScript -VM $vm -ScriptType $scriptType -ScriptText $scriptText -GuestCredential $guestCredential -Server $vCenter


#Once the script has arrived at the destination, we can simply run it.
$scriptText = $destinationScript
Invoke-VMScript -VM $vm -ScriptType $scriptType -ScriptText $scriptText -GuestCredential $guestCredential -Server $vCenter

#Mission accomplished.

Return

#this works in sending the encoded string itself to the file :)
$scriptText = "'$encodedData' | out-file -FilePath $destinationScript -Encoding ASCII"
Invoke-VMScript -VM $vm -ScriptType $scriptType -ScriptText $scriptText -GuestCredential $guestCredential -Server $vCenter

#run a powers command remotely
$scriptText = "get-disk | out-file -filepath c:\temp\get-disk.log -Encoding ASCII"
Invoke-VMScript -VM $vm -ScriptType $scriptType -ScriptText $scriptText -GuestCredential $guestCredential -Server $vCenter
