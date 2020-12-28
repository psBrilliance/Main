Get-ADGroup -Filter * -Server 'knunke.com' | ? { `
    $_.Name -match 'Domain Admins'} | Get-ADGroupMember | % { ` 
    Get-ADUser -Identity $_.SamAccountNAme -Server 'psBrilliance.com' -Properties * | Select Name, DisplayName, PasswordNeverExpires, CanonicalName, PasswordLastSet, LastLogonDate, Enabled, Created  } | `
    Export-Csv C:\temp\psBrillianceAdmins.csv -NoTypeInformation -Force
