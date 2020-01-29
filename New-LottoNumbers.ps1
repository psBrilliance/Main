Function Get-LottoNumbers ($numTickets) {
    1..$numTickets | % {(1..69 | Get-Random -Count 5) + (1..26 | Get-Random) -join ',' }
}

Get-LottoNumbers -numTickets 1
