Param(
    [Parameter(Mandatory=$true)][String]$Path,
    [Parameter(Mandatory=$true)]$Cred = (Get-Credential),
    [Parameter(Mandatory=$true)][String]$Letter
)

New-PSDrive -Name $Letter -PSProvider FileSystem -Root $Path -Credential $cred -Persist
