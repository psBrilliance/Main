$chars = [Char[]]'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890!"#%%/()=?'
($chars | Get-Random -Count 16) -join ""
