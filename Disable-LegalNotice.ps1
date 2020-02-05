$legalNoticePath = "SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System"
$objreg = [Microsoft.Win32.RegistryKey]::OpenRemoteBaseKey("LocalMachine", $Computer)
$legalNoticeTextKey = $objreg.OpenSubKey($legalNoticePath, $true)
$legalNoticeTextKey.DeleteValue("legalnoticecaption", $false)
$legalNoticeTextKey.DeleteValue("legalnoticetext", $false)
