Param(
    [Parameter(Mandatory=$true)][String]$SearchString,
    [Parameter(Mandatory=$true)][String]$SearchPath
)

$files = gci -Path $SearchPath -File -Recurse -Include *.ps1

foreach ($file in $files) { 
    if (Get-Content -Path $file.FullName | Select-String -Pattern $SearchString) {
        $file.FullName 
    }
}
