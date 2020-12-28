Param(
    [Parameter(Mandatory=$true)][String]$computerName,
    [Parameter(Mandatory=$true)][int]$range
)

1..$range | % {
    if ($_ -lt 10) {Resolve-DnsName -Name "$($computerName)0$($_).psBrilliance.com" | Select Name, IPAddress}
    else {Resolve-DnsName -Name "$($computerName)$($_).psBrilliance.com" | Select Name, IPAddress}
}
