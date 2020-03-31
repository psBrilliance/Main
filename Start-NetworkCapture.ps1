<#
.SYNOPSIS
    Functions to help create a network capture in pcapng (WireShark) format
.DESCRIPTION
    Functions enable the user to start network captures, perform the network activity and then move the paths to a network share. 
.EXAMPLE
    Start-NetWorkCapture -SourceComputer FUNWEF01 -DestComputer FUNWEF02 -Ports 3389
    Stop-NetWorkCapture
    Grab Files from '\\psbrilliance\dfs\Network\Network Captures'
.PARAMETER SourceComputer
    Enter the Source Computer for the capture
.PARAMETER DestComputer
    Enter the Destination Computer for the capture
.PARAMETER Ports
    Enter the IP Ports to filter the capture
.PARAMETER Protocol
    Use TCP, UDP or Both (TCP and UDP)
.PARAMETER DestPath
    The path where the captures will be dumped
.OUTPUTS
    ETL and PCAPNG files from network traces
.NOTES
    <Link to GitHub>
#>

Function Start-NetWorkCapture {
    Param(
        [Parameter(Mandatory=$true)][String]$SourceComputer,
        [Parameter(Mandatory=$true)][String]$DestComputer,
        [Parameter(Mandatory=$true)][Int[]]$Ports,
        [ValidateSet('TCP','UDP','Both')][String]$Protocol='Both'
    )

    $IpProtocols = switch ($Protocol) {
       'TCP'   {6;break}
       'UDP'   {17;break}
       'Both'   {6,17;break}
    }

    foreach ($server in @($SourceComputer,$DestComputer)) {
        $cimSession = New-CimSession -ComputerName $server -ErrorAction SilentlyContinue -ErrorVariable cimSessionError

        if ($cimSessionError) {
            Write-Warning $cimSessionError.Exception
            continue
        }

        #https://dscottraynsford.wordpress.com/2015/08/10/replace-netsh-trace-start-with-powershell/
        #https://docs.microsoft.com/en-us/powershell/module/neteventpacketcapture/add-neteventpacketcaptureprovider?view=win10-ps
        $netSessionName = "Capture_$($server)"
        $filterIPs = @($SourceComputer,$DestComputer) | % {(Resolve-DnsName $_ -Type A -ErrorAction SilentlyContinue).IpAddress}
        $filterIP = $filterIPs | ? {$_ -ne ((Get-NetIPAddress -AddressFamily IPv4 -CimSession $cimSession | ? {$_.IPAddress -ne '127.0.0.1'}).IPAddress | Select -First 1)}

        New-NetEventSession -Name $netSessionName -CaptureMode SaveToFile -LocalFilePath "C:\temp\$($netSessionName)_$(Get-Date -Format yyyyMMdd_HHmm).etl" -CimSession $cimSession | Out-Null
        Add-NetEventPacketCaptureProvider -SessionName $netSessionName -Level 4 -CaptureType Physical -EtherType 0x0800 -IPAddresses  $filterIP -IpProtocols $IpProtocols -CimSession $cimSession | Out-Null
        Start-NetEventSession -Name $netSessionName -CimSession $cimSession
    }
    Write-Verbose -Verbose 'Capture now in progress...'
}

Function Stop-NetWorkCapture {
    Param(
        [String]$DestPath='\\psbrilliance\dfs\Network\Network Captures'
    )
    
    foreach ($cimSession in (Get-CimSession) ) {
        $netSession = Get-NetEventSession -CimSession $cimSession
        $netSession | Stop-NetEventSession
        Start-Sleep -Seconds 2
        
        $sb = {
            $subFolder = (Split-Path $using:netSession.LocalFilePath -Leaf) -replace '\.etl'
            $fullPath = Join-Path $using:DestPath -ChildPath $subFolder

            if (!(Test-Path -Path $fullPath)) {
                New-Item -ItemType Directory -Path $fullPath | Out-Null
            }
            Copy-Item $using:netSession.LocalFilePath -Destination $fullPath
            return (Join-Path $fullPath -ChildPath (Split-Path $using:netSession.LocalFilePath -Leaf))
        }
        $eltPath = Invoke-Command -ComputerName $netSession.PSComputerName -ScriptBlock $sb -Credential
        Convert-EtlToPCAPNG -etlPath $eltPath

        $netSession | Remove-NetEventSession
        $cimSession | Remove-CimSession
    }
}

Function Convert-EtlToPCAPNG {
    Param(
        [Parameter(Mandatory=$true)][String]$etlPath,
        [Parameter(Mandatory=$false)][String]$etl2pcapngPath="\\psbrilliance\Software\PacketCaptureConverter\etl2pcapng.exe"
    )
    
    #https://github.com/microsoft/etl2pcapng
    $dest = ($etlPath -replace '\.etl','.pcapng')
    . $etl2pcapngPath $etlPath $dest | Out-Null
    Write-Verbose -Verbose "Converted PCAPNG placed: $dest"
}