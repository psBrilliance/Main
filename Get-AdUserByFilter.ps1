Param(
    [Parameter(Mandatory=$true)][String]$SearchFilter
)

Import-Module ActiveDirectory
Get-ADUser -Filter * -Server "KNUNKE.COM" -Properties EmailAddress | ? {$_.Name -match $SearchFilter -or $_.EmailAddress -match $SearchFilter} | Select Name, EmailAddress, UserPrincipalName
