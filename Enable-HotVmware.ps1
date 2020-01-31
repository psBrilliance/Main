Param(
    [Parameter(Mandatory=$true)][String]$vmName
)

$VM = Get-VM $vmName

$spec = New-Object VMware.Vim.VirtualMachineConfigSpec
$spec.memoryHotAddEnabled = $true
$spec.cpuHotAddEnabled = $true

$VM.ExtensionData.ReconfigVM_Task($spec)
