Import-Module WebAdministration
#(Get-ItemProperty 'IIS:\Sites\Default Web Site').logFile.customFields.Collection

$logField = 'SourceIPAddress'
$sourceType = 'RequestHeader'
$source = 'X-FORWARDED-FOR'

New-ItemProperty 'IIS:\Sites\Default Web Site' -Name logfile.customFields.collection -Value @{logFieldName=$logField;sourceType=$SourceType;sourceName=$source}
