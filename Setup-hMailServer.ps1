# Configure and install hMailServer for SMTP and IMAP
# Created for ISTS 16
# Author: Micah Martin (mjm5097@rit.edu)
#
# To install hMailServer run the installer as follows:
#
#	.\hMailServer-x.x.x-Bxxx.exe /verysilent
#
# To view the COM API configurations, check out the documentation:
#
#	https://www.hmailserver.com/documentation/latest/?page=com_objects
#
# Configure hmail with a new user to use SMTP and IMAP
#

param (
    [string]$domainName = "whiteteam.ists",
    [string]$newUser = "whiteteam",
    [string]$defaultPassword = "Changeme-2018"
)

##########################################
##
## Install hMailServer and connect
##
##########################################

function Install-hMail(){
    Write-Host "[*] Installing hMailServer"
    Try
    {
        $url = "https://www.hmailserver.com/download_file?downloadid=256"
        Invoke-WebRequest -Uri $url -OutFile "hMailServer.exe"
        .\hMailServer.exe /verysilent
    }
    Catch
    {
        Write-Error "[!] Install failed!"
    }
}


# Get the COM Object for hMailServer, If this fails, install hMail
Try
{
    $hMailCom = New-Object -ComObject 'hMailServer.Application'
}
Catch
{
    Install-hMail
    $hMailCom = New-Object -ComObject 'hMailServer.Application'
}

# Print info
Write-Host "[*] Configuring hMail with following settings:"
Write-Host "    - Domain Name: $domainName"
Write-Host "    - Username: $newUser"
Write-Host "    - Default Password: $defaultPassword"
Write-Host ""

# Login. After a fresh install, the password will be blank. Otherwise it is defaultPassword
Write-Host "[*] Logging in..."
$hMail = $hMailCom.Authenticate("Administrator","")
if ($hMail -eq $null) {
    $hMail = $hMailCom.Authenticate("Administrator",$defaultPassword)
    if ($hMail -ne $null) {
        Write-Host "[+] Logged in with default password"
    } else {
        Write-Error "[!] Cannot Log in"
        Throw
    }
} else {
    Write-Host "[+] Logged in with blank password" 
}

##########################################
##
## Add domains and users
##
##########################################

$domains = $hMailCom.Domains
Try
{
    # Check if the domain already exists
    $domain = $domains.ItemByName($domainName)
    # Enable the domain
    $domain.Active = $true
    $domain.Save()
    Write-Host "[+] Domain Exists. Moving on" 
}
Catch
{
    # Create a new domain name
    $domain = $domains.Add()
    # Set the name
    $domain.Name = $domainName
    # Enable the domain
    $domain.Active = $true
    $domain.Save()
    Write-Host "[*] Domain does not exists. Creating domain"
}

# Get the accounts of the domain
Try
{
    $account = $accounts.ItemByAddress("$newUser@$domainName")
    # Set the password and activate the account
    $account.Password = $defaultPassword
    $account.Active = $true
    $account.Save()
    Write-Host "[+] $newUser@$domainName exists already."
}
Catch
{
    $account = $accounts.Add()
    # Set the email address, password, and activate the account
    $account.Address = "$newUser@$domainName"
    $account.Password = $defaultPassword
    $account.Active = $true
    $account.Save()
    Write-Host "[*] $newUser@$domainName created with default password"
}

##########################################
##
## Configure key settings
##
##########################################

$settings = $hMailCom.Settings

Write-host "[*] Resetting Admin password"
$settings.SetAdministratorPassword($defaultPassword)

Write-Host '[*] Enabling services'
$settings.ServiceIMAP = $true
$settings.ServicePOP3 = $false
$settings.ServiceSMTP = $true

Write-Host "[*] Configuring services"
$settings.AllowSMTPAuthPlain = $true
$settings.HostName = $domainName
$settings.DefaultDomain = $domainName
$settings.IMAPIdleEnabled = $true
$settings.AutoBanOnLogonFailure = $false

$log = $settings.Logging
Write-Host "[*] Enabling logging"
$log.Enabled = $true
$log.AWStatsEnabled = $true
$log.LogApplication = $true
$log.LogIMAP = $true
$log.LogSMTP = $true
$log.LogTCPIP = $true
$log.MaskPasswordsInLog = $false

Write-Host "[+] Complete. hMail installed"

