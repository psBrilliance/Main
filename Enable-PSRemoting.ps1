#Requires -RunAsAdministrator
Enable-PSRemoting -Force -SkipNetworkProfileCheck

Set-Item WSMan:\localhost\Client\TrustedHosts -Value "*" -Force
