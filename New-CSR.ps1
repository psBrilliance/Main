#Requires -RunAsAdministrator

<#
    .SYNOPSIS
    Generate CSR file\content for generation of new certs

    .DESCRIPTION
    Input the FQDN and options SAN parameters to generate a file with the content for your CSR
    Script will create a file and also display the content

    .PARAMETER FQDN
    The FQDN (Fully Quailified Domain Name) aka Subject of your certificate
    This is also accept * for Wilcard certificates

    .PARAMETER SANs
    Optional SAN (Subject Alternative Name) can also be defined. 
    This is an array string so multiable SANs can be defined

    .EXAMPLE
    .\New-CSRFile.ps1 -FQDN 'psbrilliance.com' -SANs 'test1.psbrilliance.com,test2.psbrilliance.com'
    .\New-CSRFile.ps1 -FQDN '*.psbrilliance.com'
#>

Param(
    [Parameter(Mandatory=$true)][String]$FQDN,
    [Parameter(Mandatory=$false)][String[]]$SANs
)

$path = "C:\Temp"
$Date = (Get-Date).ToString('dd_MM_yy')
$csrFile = "Cert_CSR-$FQDN-$Date.csr"
$Subject = ($FQDN).Trim()
    
$InfFile = @"
            [NewRequest]`r`n
            Subject = "CN=$subject,OU=IT,O=PSBrillance,L=Chicago,S=Illinois,C=US"`r
            Exportable = TRUE             ; TRUE = Private key is exportable`r
            KeyLength = 2048              ; Valid key sizes: 1024, 2048, 4096, 8192, 16384`r
            KeySpec = 1                   ; Key Exchange – Required for encryption`r
            KeyUsage = 0xA0               ; Digital Signature, Key Encipherment`r
            HashAlgorithm = SHA256        ; Uses SHA-256 instead of default SHA-1`r
            ProviderName = "Microsoft RSA SChannel Cryptographic Provider"`r
            MachineKeySet = TRUE`r
            FriendlyName = "Web Cert - $Subject"`r

            [EnhancedKeyUsageExtension]`r`n
            OID=1.3.6.1.5.5.7.3.1           ; Server Authentication`r
            OID=1.3.6.1.5.5.7.3.2           ; Client Authentication`r`n

"@
        
if ($SANs -ne $null) {
        $InfFile += @"
            [Extensions]`r`n
            2.5.29.17 = "{text}"`r
            _continue_ = "
"@
            foreach ($SAN in $SANs) {
                $InfFile += "dns=$SAN&"
            }
                
            $InfFile += '"`r' 
    }

$FinalInfFile = "Cert_Req_Inf-$Subject-$Date.inf"

if ($csrFile -match "\*") { 
    $csrFile=$csrFile.Replace("*","WC")
    $FinalInfFile=$FinalInfFile.Replace("*","WC") 
}

$infFilePath = Join-Path $path -ChildPath "$FinalInfFile"
$csrFilePath = Join-Path $path -ChildPath "$csrFile"

New-Item -Path $infFilePath -Type File -Value $InfFile -Force | Out-Null
cmd /c "certreq -new -f $infFilePath $csrFilePath" | Out-Null

Remove-Item $infFilePath
Get-Content $csrFilePath
Write-Verbose -Verbose "CSR: $csrFilePath"
