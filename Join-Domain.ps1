Param(
    [Parameter(Mandatory=$false)][String]$IpAddress='10...',
    [Parameter(Mandatory=$false)][String]$Gateway='10...',
    [Parameter(Mandatory=$false)][Int]$Prefix=24,
    [Parameter(Mandatory=$false)][String]$ComputerName='LJWNEFLK',
    [Parameter(Mandatory=$false)][String]$OUPath='OU=Web,OU=Servers,DC=PSBRILLIANCE,DC=COM',
    [Parameter(Mandatory=$false)][String[]]$DnsServers=@('8.8.8.8','8.8.4.4')
)
if (!((Test-NetConnection -ComputerName $gateway).PingSucceeded)) {
    $adapter = Get-NetAdapter -Physical

    $adapter | New-NetIPAddress -IPAddress $IpAddress -PrefixLength $Prefix -DefaultGateway $Gateway | Out-Null
    $adapter | Set-DnsClientServerAddress -ServerAddresses $DnsServers
    Start-Sleep -Seconds 5
}

if ((Test-NetConnection -ComputerName $gateway).PingSucceeded) {
    $cred = Get-Credential -Message 'Enter Creds for joining to domain'

    $join = Add-Computer -DomainName 'SaaS.TBS' -Credential $cred -OUPath $ouPath -Force -WarningAction SilentlyContinue -PassThru
    if ($join.HasSucceeded -ne 'Succeed' ) {
        Rename-Computer -DomainCredential $cred -NewName $ComputerName -Force -WarningAction SilentlyContinue
    }
    Restart-Computer -Force
}
