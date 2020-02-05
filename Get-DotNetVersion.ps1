$computers = Get-Content "C:\CTX\Tasks\Get-PilotUpdates\knunke pilot.txt"

$payload = {
    Function Get-DotNetVersion {
        $Lookup = @{378389 = '4.5';378675 = '4.5.1';378758 = '4.5.1';379893 = '4.5.2';393295 = '4.6';393297 = '4.6';394254 = '4.6.1';394271 = '4.6.1';394802 = '4.6.2';394806 = '4.6.2';460798 = '4.7';460805 = '4.7';461308 = '4.7.1';461310 = '4.7.1';461808 = '4.7.2';461814 = '4.7.2';528040 = '4.8';528049 = '4.8'}

        gci 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse |
          Get-ItemProperty -Name Version, Release -EA 0 |
            ? { $_.PSChildName -match '^(?!S)\p{L}'} |
                Select @{N="DotNetFramework";E={$_.PSChildName}}, @{N="Product";E={$Lookup[$_.Release]}}, Version, Release |
                    ? {$_.DotNetFramework -eq 'Full'} | Select -ExpandProperty Product
    }
    Function Get-PendingReboot {
        if (Get-ChildItem "HKLM:\Software\Microsoft\Windows\CurrentVersion\Component Based Servicing\RebootPending" -EA Ignore) { return $true }
        if (Get-Item "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\WindowsUpdate\Auto Update\RebootRequired" -EA Ignore) { return $true }
        
        try { 
            $util = [wmiclass]"\\.\root\ccm\clientsdk:CCM_ClientUtilities"
            $status = $util.DetermineIfRebootPending()
            
            if(($status -ne $null) -and $status.RebootPending){
                return $true
            }
        }catch{}
        return $false
    }

    New-Object PSObject -Property @{
        IpAddress = (Get-NetIPAddress -AddressFamily IPv4).IPAddress | ? {$_ -match '10\.' -and $_ -notmatch '10\.101\.10|172\.28'}
        DotNetVersion = Get-DotNetVersion
        LastPatch = Get-Date (Get-HotFix | Sort InstalledOn -Descending | Select -First 1 -ExpandProperty InstalledOn) -Format G
        PendingReboot = Get-PendingReboot
        LastRebooted = Get-Date ([System.Management.ManagementDateTimeconverter]::ToDateTime((Get-WmiObject -Class Win32_OperatingSystem).LastBootUpTime)) -Format G
    }
}

function Job-Throttle ($collection, $payload, $maxjobs,$jobtimeout) {
      $results = @()
    Write-Progress -Activity 'Processing jobs..' -PercentComplete (0) -Status 'Starting' -Id 123
      for ($i=0;$i -lt $collection.Count; $i++) {
          Write-Progress -Activity 'Processing jobs..' -Status $collection[$i] -Id 123 `
                -PercentComplete ($i/($collection.count/100))
            while ((Get-Job).Count -eq $maxjobs) {
                  foreach ($job in @(Get-job | where {$_.State -ne 'Completed'})) {
                        if ((New-TimeSpan -Start $job.PSBeginTime -End (Get-Date)).Seconds -ge $jobtimeout -and $job.State -eq 'Running')     {
                              Write-Host "Removing job $($job.location) due to timeout" -ForegroundColor Red
                              Remove-Job $job -Force  | Out-Null
                        }
                elseif ($job.State -ne 'Running') {
                    Write-Host "Removing job $($job.location) due to $($job.State)" -ForegroundColor Red
                    Remove-Job $job -Force | Out-Null
                }
                  }
                  foreach ($job in @(Get-job | where {$_.State -eq 'Completed'})) {
                        Write-Host "Receiving job $($job.location)" -ForegroundColor DarkGreen
                        $result = Receive-Job $job
                Remove-Job $job -Force | Out-Null
                $results += $result
                  }
                  if ((Get-Job).Count -ge $maxjobs) {
                        Start-Sleep -Seconds 3
                  }
            }
            if ((Get-Job).Count -lt $maxjobs) {
                  Write-Host "Starting job $i" -ForegroundColor DarkCyan
            Invoke-Command -ScriptBlock $payload -ComputerName $collection[$i] -AsJob | Out-Null
                  #Start-Job -ScriptBlock $payload | Out-Null
            }
      }
      while ((Get-Job).Count -gt 0) {
            foreach ($job in @(Get-job | where {$_.State -ne 'Completed'})) {
                  if ((New-TimeSpan -Start $job.PSBeginTime -End (Get-Date)).Seconds -ge $jobtimeout -and $job.State -eq 'Running')      {
                        Write-Host "Removing job $($job.location) due to timeout" -ForegroundColor Red
                        Remove-Job $job -Force | Out-Null
                  }
            elseif ($job.State -ne 'Running') {
                Write-Host "Removing job $($job.location) due to $($job.State)" -ForegroundColor Red
                Remove-Job $job -Force | Out-Null
            }
            }
            foreach ($job in @(Get-job | where {$_.State -eq 'Completed'})) {
                  Write-Host "Receiving job $($job.location)" -ForegroundColor DarkGreen
                  $result = Receive-Job $job
            Remove-Job $job -Force | Out-Null
            $results += $result
            }
            if ((Get-Job).Count -gt 0) {
                  Start-Sleep -Seconds 3
            }
      }
    Write-Progress -Completed -Activity 'Processing jobs..' -Id 123
      $results
}

$data = Job-Throttle $computers $payload 10 60
$data | Select PSComputerName,IpAddress,DotNetVersion,PendingReboot,LastRebooted,LastPatch | ft -AutoSize
