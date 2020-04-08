Function Initialize-JobQueue {
    Param(
        [Parameter(Mandatory)]$Collection,
        [Parameter(Mandatory)]$Payload,
        [Parameter(Mandatory)][int]$JobMax,
        [Parameter(Mandatory)][int]$JobTimeout
    )
    
    function Start-JobQueue {
        foreach ($job in @(Get-Job | ? {$_.State -ne 'Completed'})) {
            if ((New-TimeSpan -Start $job.PSBeginTime -End (Get-Date)).Seconds -ge $jobtimeout -and $job.State -eq 'Running') {
                Write-Host "Removing job $($job.location) due to timeout" -ForegroundColor Red
                Remove-Job $job -Force  | Out-Null
            }
            elseif ($job.State -ne 'Running') {
                Write-Host "Removing job $($job.location) due to $($job.State)" -ForegroundColor DarkRed
                Remove-Job $job -Force | Out-Null
            }
        }

        foreach ($job in @(Get-job | where {$_.State -eq 'Completed'})) {
            Write-Host "Receiving job $($job.location)" -ForegroundColor DarkGreen
            Receive-Job $job
                        
            Remove-Job $job -Force | Out-Null
        }

        if ((Get-Job).Count -ge $maxjobs) {
            Start-Sleep -Seconds 3
        }
    }

    $results = @()
    Write-Progress -Activity 'Processing jobs..' -PercentComplete (0) -Status 'Starting' -Id 123
        for ($i=0;$i -lt $collection.Count; $i++) {
            Write-Progress -Activity 'Processing jobs..' -Status $collection[$i] -Id 123 -PercentComplete ($i/($collection.count/100))
            
            while ((Get-Job).Count -eq $maxjobs) {
                $results += Start-JobThrottle
            }
            if ((Get-Job).Count -lt $maxjobs) {
                Write-Host "Starting job $i" -ForegroundColor DarkCyan
                Start-Job -ScriptBlock $payload -ArgumentList $collection[$i] | Out-Null
            }
      }
      
        while ((Get-Job).Count -gt 0) {
            $results += Start-JobThrottle
            
            if ((Get-Job).Count -gt 0) {
                  Start-Sleep -Seconds 3
            }
      }
      
      Write-Progress -Activity 'Processing jobs..' -Id 123 -Completed
      $results
}
