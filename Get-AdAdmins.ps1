Get-ADGroup -Filter * -Server 'knunke.com' | ? { `
    $_.Name -match 'Domain Admins'} | Get-ADGroupMember | % { ` 
    Get-ADUser -Identity $_.SamAccountNAme -Server 'knunke.com' -Properties * | Select Name, DisplayName, PasswordNeverExpires, CanonicalName, PasswordLastSet, LastLogonDate, Enabled, Created  } | `
    Export-Csv C:\temp\knunkeAdmins.csv -NoTypeInformation -Force
