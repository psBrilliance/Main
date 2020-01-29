Param(
    [Parameter(Mandatory=$true)][string]$DnsServer,
    [Parameter(Mandatory=$true)][string]$CsvPath,
    [Parameter(Mandatory=$true)]$cred = (Get-Credential)
)

$hostlist = Import-Csv $CsvPath

[scriptblock]$myblock = {
    Import-Module DnsServer
    
    foreach ($dnshost in $using:hostlist) {
        Add-DnsServerResourceRecordA -Name $dnshost.host -ZoneName "knunke.com" -IPv4Address $dnshost.ip -ComputerName $dnsServer
    }
}

Invoke-Command -ScriptBlock $myblock -ArgumentList @($hostlist) -Credential $cred -ComputerName $dnsServer
