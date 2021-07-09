##############################################################################################################################
#
# This script must be run elevated and needs to be run on all XenDesktop Delivery Controller.
# It also asumes that the database has already been moved to the new SQL server and the necessary logins created.
# 
# More Informations (make sure you read them first!):
#    https://support.citrix.com/article/CTX140319
#    https://docs.microsoft.com/en-us/sql/relational-databases/databases/copy-databases-with-backup-and-restore
#
# Preparation steps:
#
#    1. Backup Registry.
#
#    2. Backup the Existing Databases and restore them onto the SQL target server. There are typically three databases: one for 
#	   the site, one for Monitoring, and one for Logging. Refer to the Microsoft article mentioned above for more information.
#
#    3. Verify that all the Delivery Controllers have valid logins for their machine account in the form DomainName\Computername$ 
#       on the database server. Refer to the Citrix article mentioned above for more information.
#
#       Read the process description here 
#
##############################################################################################################################

# Change the variables to match your environment
[string]$OldSQLServer = "OLDSQLSERVER" # if there are any errors, try OLDSERVER\OLDINSTANCE
[string]$NewSQLServer = "NEWSQLSERVER" # if there are any errors, try NEWSERVER\NEWINSTANCE


##############################################################################################################################
# Normally nothing to change below this comment
##############################################################################################################################

Write-Host "Adding Citrix SnapIns" -ForegroundColor Black -BackgroundColor Yellow
Add-PSSnapin Citrix* -ErrorAction Stop

# Test that all brokers are the same version
if ((Get-BrokerController | Select-Object ControllerVersion -Unique | Measure).Count -ne 1) {
    Write-Error "Multiple delivery controller versions found. Recommended to have the same version throughout before upgrading"
    break
}
[int]$Version = (Get-BrokerController | Select-Object -ExpandProperty ControllerVersion -Unique).Split(".")[1]

Write-Host "Stopping Logging" -ForegroundColor Black -BackgroundColor Yellow
Set-LogSite -State "Disabled"
Set-MonitorConfiguration -DataCollectionEnabled $False

Write-Host "Updating Connection String" -ForegroundColor Black -BackgroundColor Yellow
$ConnStr = Get-ConfigDBConnection
Write-Host "Old Connection String: $ConnStr"
$ConnStr = $ConnStr.Replace($OldSQLServer,$NewSQLServer)
Write-Host "New Connection String: $ConnStr"

if ([String]::IsNullOrWhiteSpace($Connstr)) {
    Write-Error "New connection string appears to be empty. Unable to proceed"
    break
}

$PromptTitle = "Confirm New Connection String"
$PromptMessage = "Is the new connection string shown above correct?"
$PromptYes = New-Object System.Management.Automation.Host.ChoiceDescription "&Yes", "Change the Database Connection."
$PromptNo = New-Object System.Management.Automation.Host.ChoiceDescription "&No", "Stop! This connection string is wrong!"
$PromptOptions = [System.Management.Automation.Host.ChoiceDescription[]]($PromptNo, $PromptYes)
$Result = $Host.UI.PromptForChoice($PromptTitle, $PromptMessage, $PromptOptions, 0) 
if ($Result -ne 1) { return }

# Clear error history, we can then check it at the end. 
$Error.Clear()

# Clear current DB connections to the old database
Write-Host "Clearing all current DB Connections" -ForegroundColor Black -BackgroundColor Yellow
Set-ConfigDBConnection -DBConnection $null
if ([int]$Version -ge 6) { Set-AnalyticsDBConnection -DBConnection $null }
if ([int]$Version -ge 8) { Set-AppLibDBConnection -DBConnection $null }
if ([int]$Version -ge 11) { Set-OrchDBConnection -DBConnection $null }
if ([int]$Version -ge 11) { Set-TrustDBConnection -DBConnection $null }
Set-HypDBConnection -DBConnection $null
Set-ProvDBConnection -DBConnection $null
Set-BrokerDBConnection -DBConnection $null
Set-AcctDBConnection -DBConnection $null
Set-EnvTestDBConnection -DBConnection $null
Set-SfDBConnection -DBConnection $null
Set-MonitorDBConnection -DataStore Monitor -DBConnection $null
Set-MonitorDBConnection -DBConnection $null
Set-LogDBConnection -DataStore Logging -DBConnection $null
Set-LogDBConnection -DBConnection $null
Set-AdminDBConnection -DBConnection $null

# Configuring connections to the new database
Write-Host "Configuring new DB Connections" -ForegroundColor Black -BackgroundColor Yellow
Set-AdminDBConnection -DBConnection $ConnStr
Set-ConfigDBConnection -DBConnection $ConnStr
Set-AcctDBConnection -DBConnection $ConnStr
if ([int]$Version -ge 6) { Set-AnalyticsDBConnection -DBConnection $ConnStr }
Set-HypDBConnection -DBConnection $ConnStr
Set-ProvDBConnection -DBConnection $ConnStr
if ([int]$Version -ge 8) { Set-AppLibDBConnection -DBConnection $ConnStr }
if ([int]$Version -ge 11) { Set-OrchDBConnection -DBConnection $ConnStr }
if ([int]$Version -ge 11) { Set-TrustDBConnection -DBConnection $ConnStr }
Set-BrokerDBConnection -DBConnection $ConnStr
Set-EnvTestDBConnection -DBConnection $ConnStr
Set-SfDBConnection -DBConnection $ConnStr
Set-LogDBConnection -DBConnection $ConnStr
Set-LogDBConnection -DataStore Logging -DBConnection $ConnStr
Set-MonitorDBConnection -DBConnection $ConnStr
Set-MonitorDBConnection -DataStore Monitor -DBConnection $ConnStr

# Test database connection
Write-Host "Testing new DB Connections..." -ForegroundColor Black -BackgroundColor Yellow
Test-AcctDBConnection -DBConnection $ConnStr
Test-AdminDBConnection -DBConnection $ConnStr
if ($Version -ge 6) { Test-AnalyticsDBConnection -DBConnection $ConnStr }
if ($Version -ge 8) { Test-AppLibDBConnection -DBConnection $ConnStr }
Test-BrokerDBConnection -DBConnection $ConnStr
Test-ConfigDBConnection -DBConnection $ConnStr
Test-EnvTestDBConnection -DBConnection $ConnStr
Test-HypDBConnection -DBConnection $ConnStr
Test-LogDBConnection -DBConnection $ConnStr
Test-MonitorDBConnection -DBConnection $ConnStr
if ($Version -ge 11) { Test-OrchDBConnection -DBConnection $ConnStr }
Test-ProvDBConnection -DBConnection $ConnStr
Test-SfDBConnection -DBConnection $ConnStr
if ($Version -ge 11) { Test-TrustDBConnection -DBConnection $ConnStr }

# Enable XenDesktop logging
Write-Host "Re-enabling Logging" -ForegroundColor Black -BackgroundColor Yellow
Set-MonitorConfiguration -DataCollectionEnabled $true
Set-LogSite -State "Enabled"

# Check database details
Write-Host "Get details of all new DB Connection strings"
Get-ConfigDBConnection 
if ([int]$Version -ge 6) { Get-AnalyticsDBConnection  }
if ([int]$Version -ge 8) { Get-AppLibDBConnection  }
if ([int]$Version -ge 11) { Get-OrchDBConnection  }
if ([int]$Version -ge 11) { Get-TrustDBConnection  }
Get-HypDBConnection 
Get-ProvDBConnection 
Get-BrokerDBConnection 
Get-EnvTestDBConnection 
Get-SfDBConnection 
Get-MonitorDBConnection 
Get-MonitorDBConnection -DataStore Monitor 
Get-LogDBConnection -DataStore Logging 
Get-LogDBConnection 
Get-AdminDBConnection 
Get-AcctDBConnection

if ($Error.Count -gt 0) {
    Write-Error "There have been issues changing the database connection. Please check the current connection strings and update any that are incorrect before restarting services"
    break
}

# Starting neccessary services
Write-Host "Restarting all Citrix Services..." -ForegroundColor Black -BackgroundColor Yellow
Get-Service Citrix* | Stop-Service -Force
Get-Service Citrix* | Start-Service
