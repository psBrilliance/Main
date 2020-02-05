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

$sb = {
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
}

$computers = (1..9 | % {"KNUNKE0$_"}) + ('KNUNKE10')

$data = Job-Throttle $computers $sb 10 60
$data | Select Server, BeforeSizeGB, AfterSizeGB | ft -AutoSize
