Import-Module Selenium

$cred = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList 'psBrilliance@gmail.com', ('MyAmazingPassword' | ConvertTo-SecureString -AsPlainText -Force)

$websites = @(
    'https://www.bestbuy.com/site/sony-playstation-5-console/6426149.p?skuId=6426149'
    'https://www.target.com/p/playstation-5-console/-/A-81114595#lnk=sametab'
    'https://www.amazon.com/dp/B08FC5L3RG/ref=cm_sw_em_r_mt_dp_6as1Fb6YYTFPW'
    'https://www.costco.com/sony-playstation-5-gaming-console-bundle.product.100691489.html'
    'https://www.gamestop.com/video-games/playstation-5/consoles/products/playstation-5/11108140.html?condition=New'
    'https://www.walmart.com/ip/PlayStation-5-Console/363472942'
    'https://direct.playstation.com/en-us/consoles/console/playstation5-console.3005816'
)
$driver = Start-SeChrome

while ($true) {
    foreach ($website in $websites) {
        Enter-SeUrl -Driver $Driver -Url $website
        $url = ($website -split '/')[2]
        Start-Sleep -Seconds 2

        $element = switch -Wildcard ($url) {
            "*Amazon*"        { 
                $first = Find-SeElement -Driver $Driver -ClassName 'a-last'
                if ($first.Text -match 'robot') {
                    New-Object PSObject -Property @{
                        Text = 'Robot'
                    }
                } else {
                    $second = $driver.FindElementByXPath('//*[@id="availability"]/span')
                    if ($second.Text -eq '' -or $second.Text -eq $null) {
                        $driver.FindElementByXPath('//*[@id="submit.add-to-cart-announce"]')
                    } else { $second }
                }
            }
            "*BestBuy*"       { Find-SeElement -Driver $Driver -ClassName "add-to-cart-button" | Select -First 1 }
            "*Playstation*"   { 
                try {
                    try {
                        $first = $driver.FindElementByXPath('//*[@id="main_c"]/div[2]/ul[1]/li[1]')
                        if ($first.Text -match 'entered into the queue') {
                            New-Object PSObject -Property @{
                                Text = 'Queue!'
                            }
                        }
                    } catch {
                        $second = $driver.FindElementById('lbHeaderH2')
                        if ($second.Text -eq "We're working to get you in.") {
                            New-Object PSObject -Property @{
                                Text = 'Robot'
                            }
                        }
                    }
                } catch {
                    $third = $driver.FindElementByXPath('/html/body/div[1]/div/div[3]/producthero-component/div/div/div[3]/producthero-info/div/div[4]/div[2]/p')
                    if ($third.Text -eq 'Out of Stock') {
                        $third
                    } elseif ($third.Text -eq '') {
                        New-Object PSObject -Property @{
                            Text = 'Out of Stock'
                        }
                    }
                    else { $driver.FindElementByXPath('/html/body/div[1]/div/div[3]/producthero-component/div/div/div[3]/producthero-info/div/div[4]/button') }
                }
            }
            "*Target*"        { 
                $first = (Find-SeElement -Driver $Driver -ClassName "h-padding-t-tight")[1].Text -split "`n" | Select @{N='Text';E={($_).Trim()}} -First 1
                if ($first.Text -eq '' -or $first.Text -eq $null) {
                    Find-SeElement -Driver $Driver -ClassName 'iyUhph'
                } else { $first }
            }
            "*GameStop*"      { 
                try {
                    $first = $driver.FindElementByXPath('/html/body/h1')
                    if ($first.Text -eq 'Access Denied') {
                        New-Object PSObject -Property @{
                            Text = 'Robot'
                        }
                    }
                }
                catch {
                    $second = $driver.FindElementByXPath('//*[@id="primary-details"]/div[4]/div[9]/div[2]/div[1]/label/div/div[5]/span[2]')
                    if ($second.Text -eq '' -or $second.Text -eq $null) {
                        $driver.FindElementByXPath('//*[@id="primary-details"]/div[4]/div[13]/div[3]/div/div[1]/button')
                    } else {
                        $second
                    }
                }
            }
            "*CostCo*"        {
                $ele=Find-SeElement -Driver $Driver -ClassName "oos-overlay"
                if ($ele.Enabled) { 
                    $ele | Select @{N='Text';E={'Out of Stock'}} 
                } else {
                    New-Object PSObject -Property @{
                        Text = 'Out of Stock'
                    }
                }
            }
            "*Walmart*"       { 
                $first = Find-SeElement -Driver $Driver -ClassName 'bot-message'
                if ($first.Text -match 'account safe') {
                    New-Object PSObject -Property @{
                        Text = 'Robot'
                    }
                } else {
                    $second = Find-SeElement -Driver $Driver -ClassName 'error-page-message' | Select -First 1
                    if ($second.Text -eq 'Oops! This item is unavailable or on backorder.') {
                        $second   
                    } else {
                        $third = Find-SeElement -Drive $driver -className "prod-blitz-copy-message"
                        if ($third.Text -eq 'This item is out of stock.') {
                            $third
                        } else {
                            Find-SeElement -Driver $Driver -ClassName 'spin-button-children'
                        }
                    }
                }
            }
        }
    
        "$(Get-Date),$url,$($element.Text)" | Out-File -Append -FilePath "C:\TEMP\results2.txt" -Encoding ascii

        if ($element.Text -notmatch 'Out of Stock|Sold Out|Currently unavailable|or on backorder|Coming Soon|Robot|NOT AVAILABLE') {
            #https://myaccount.google.com/lesssecureapps
            Send-MailMessage -To 'psBrilliance@gmail.com' -From 'psBrilliance@gmail.com'  -Subject 'PS5 Restock Script' -Body "$(Get-Date)`n$url`n$($element.Text)`n`n$website" -Credential $cred -SmtpServer 'smtp.gmail.com' -Port '587' -UseSsl
        }

        Start-Sleep -Seconds (2..50 | Get-Random)
    }
}
$driver.Quit()
