Function Format-Number ($number) {
  return [Math]::Round(($number/1GB),2)
}

$before = Format-Number ((Get-PSDrive -Name C).Used + (Get-PSDrive -Name C).Free)
Resize-Partition -DriveLetter c -Size (Get-PartitionSupportedSize -DriveLetter C).sizeMax
$after = Format-Number ((Get-PSDrive -Name C).Used + (Get-PSDrive -Name C).Free)

New-Object PSObject -Property @{
  Server = $env:COMPUTERNAME
  BeforeSizeGB = $before
  AfterSizeGB = $after
}
