Param(
    [Parameter(Mandatory=$true)][String[]]$ComputerName,
    [Parameter(Mandatory=$false)][String[]]$Cred
)

Invoke-Command -ComputerName $ComputerName -ScriptBlock { $env:COMPUTERNAME } -Credential $cred
