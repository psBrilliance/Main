Param(
    [Parameter(Mandatory=$true)][String]$xmlPath
)

[xml]$XmlDocument = Get-Content -Path $xmlPath
$settings = $XmlDocument.DefaultValues.DefaultValue
$settings
