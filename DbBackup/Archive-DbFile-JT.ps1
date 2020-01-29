. C:\CTX\Scripts\DbBackup\Import-DbBackupFunctions.ps1
$startTime = Get-Date

Start-Script ($MyInvocation.MyCommand.Name)

$SQLCheck = "SELECT * FROM $($connectionInfo.Table) WHERE CatalogedDate > DATEADD(d,-60,GETDATE()) AND (ArchiveDate IS NULL);"
$sqlResults = Invoke-SQL -SQLInstance $connectionInfo.Instance -DatabaseName $connectionInfo.Database -SQLQuery $SQLCheck

$amount = 15
$subCollection = Split-Collection $sqlResults $amount

$payLoad = {
    . C:\CTX\Scripts\DbBackup\Import-DbBackupFunctions.ps1
    $sqlSubResult = $args

    $knunkeTestPaths = (gci '\\knunkeisi.knunke.com\DBBackup\TapeQueue' -Directory).FullName
    $knunkeTestPaths += ((gci '\\knunkeisi.knunke.com\DBBackup\Servers' -Directory) | ? { $_.Name -match "TEST" }).FullName

    $knunkeTestACIPaths = (gci '\\prodknunkesmb\DbBackupknunke\TapeQueue' -Directory).FullName
    $knunkeTestACIPaths += ((gci '\\prodknunkesmb\DbBackupknunke\Servers' -Directory) | ? { $_.Name -match "TEST" }).FullName

    Function Find-DbFiles {
        $i=1;foreach ($result in $sqlSubResult) {
                switch ($result.Domain) {
                    "knunke.com"    { 
                        Archive-DbFile $knunkeTestPaths $result (($knunkePath).Replace("Servers","Archive")) 
                    }
                    "knunke.com|ACI"    { 
                        Archive-DbFile $knunkeTestACIPaths $result (($knunkeACIPath).Replace("Servers","Archive")) 
                    }
                    "prod.knunke.com" {
                        Archive-DbFile ("$TaxtechPath\Prod\Servers") $result ("$TaxtechPath\Prod\Archive")
                        Archive-DbFile ("$TaxtechPath\PreProd\Servers") $result ("$TaxtechPath\PreProd\Archive")
                    }
                    "dev.knunke.com" {Write-Host 'Cscinfo.com'}
                }
            $i++
        }
    }
    Function Archive-DbFile ($testPaths, $sqlResult, $archiveLocation) {
    
    $testPaths | % { 
        $testFile = Join-Path $_ -ChildPath ("$($sqlResult.Instance)\$($sqlResult.FileName)")
        <#
        if ($_ -match 'Servers') {
            $testFile = Join-Path $_ -ChildPath "$($sqlResult.FileName)"
        }
        else { $testFile = Join-Path $_ -ChildPath ("$($sqlResult.Instance)\$($sqlResult.FileName)") }
        #>
        #Write-Host "Testing: $testFile" -ForegroundColor Cyan
        if (Test-Path ($testFile)) {
            Write-Host "From: $testFile `nTo:   $("$archiveLocation\$($sqlResult.Instance)\$($sqlResult.FileName)")" -ForegroundColor Green
            Move-Item $testFile -Destination "$archiveLocation\$($sqlResult.Instance)\$($sqlResult.FileName)"

            $sqlUpdate = "UPDATE DbBackup SET ArchiveDate='$(Get-Date)' WHERE FileName='$($sqlResult.FileName)' AND Instance='$($sqlResult.Instance)' AND Domain='$($sqlResult.Domain)'"
            Invoke-SQL -SQLInstance $connectionInfo.Instance -DatabaseName $connectionInfo.Database -SQLQuery $sqlUpdate

        }
    }
}

    Find-DbFiles
}

for ($i=1;$i -le $amount;$i++) {
    Start-Job -ScriptBlock $payload -ArgumentList $subCollection."Group$i" | Out-Null
}

while (Get-Job -State Running) { 
    Write-Host "There are $((Get-Job -State Running).Count) jobs still running $(Get-Date)" -ForegroundColor DarkMagenta
    Start-Sleep -Seconds 60 
}

$jobs = Get-Job
$jobs | Sort ID | Receive-Job
$jobs | Remove-Job -Force

End-Script ($MyInvocation.MyCommand.Name)
