# ----------------------------------------------------
#
# Trust Broker XML Port
#
# 2015 Thomas Krampe - t.krampeloginconsultants.com
# Login Consultants Germany GmbH
#
# ----------------------------------------------------

Set-ExecutionPolicy Bypass
Import-Module citrix.*
Add-PSSnapin citrix.*

Write-Host "Set XML Port Trust"
Set-BrokerSite -TrustRequestsSentToTheXmlServicePort $True