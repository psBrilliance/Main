Param(
    [Parameter(Mandatory=$true)][String]$Password
)

$Password | ConvertTo-SecureString -AsPlainText -Force | ConvertFrom-SecureString | Out-File "C:\Temp\Creds\$($env:USERNAME).sec"
