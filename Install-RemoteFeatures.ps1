Param(
    [Parameter(Mandatory=$true)][String]$remoteComputer
)

Get-WindowsFeature -ComputerName $remoteComputer | ? { $_.Installed  } | Add-WindowsFeature
