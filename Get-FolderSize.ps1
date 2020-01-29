Param(
    [Parameter(Mandatory=$true)][String]$folderPath
)

$folerSize = (gci $folderPath | Measure-Object -Property Length -Sum) 
"{0:N2}" -f ($folerSize.Sum / 1MB) + " MB"
