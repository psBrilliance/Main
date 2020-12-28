$Domain = 'psBrilliance.com'
$UserToChange = 'admin'
$newPwd = 'pwnz0red'
$oldPwd = 'iForgot'

$secNewPwd = ConvertTo-SecureString –String $newPwd –AsPlainText -Force
$secOldPwd = ConvertTo-SecureString –String $oldPwd –AsPlainText -Force

Set-ADAccountPassword -Server $Domain -Identity $UserToChange -OldPassword $secOldPwd -NewPassword $secNewPwd 
