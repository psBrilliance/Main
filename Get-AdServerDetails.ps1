Get-ADComputer -Filter * -Properties LastLogonDate,IPv4Address,OperatingSystem,ObjectCategory  | 
    Select Name, LastLogonDate, IPv4Address, OperatingSystem, ObjectCategory, 
        @{N='IsPingable';E={Test-Connection -ComputerName $_.IPv4Address -Quiet -Count 1}}, @{N='Domain';E={'knunke.com'}} | Export-csv C:\temp\knunke.com.csv -NoTypeInformation
