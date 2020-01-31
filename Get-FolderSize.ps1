Param(
    [Parameter(Mandatory=$true)][String]$Path
)

"{0:N2}" -f ((gci -Path $Path -Recurse -File | % {$_.Length} | Measure-Object -Sum).Sum / 1MB) + " MB"
