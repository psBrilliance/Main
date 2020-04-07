Param(
    [Parameter(Mandatory)][String]$SearchString,
    [Parameter(Mandatory)][String]$Path
)

$files = gci -Path $Path -File -Recurse -Include *.ps1

$results = foreach ($file in $files) { 
    $hasString = Get-Content -Path $file.FullName | Select-String -Pattern $SearchString
    if ($hasString) {
        New-Object PSObject -Property @{
            ScriptPath = $file.FullName
            Count = ($hasString | Measure-Object).Count
        }
    }
}
$results | Sort Count -Descending
