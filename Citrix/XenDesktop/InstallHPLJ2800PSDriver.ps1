####################################################################################################
#
# Script to Install HP LaserJet 2800 Series PS Driver
#
# Author: Thomas Krampe - t.krampe@loginconsultants.de
# Date:   05.11.2018
# Notes:  Citrix KB http://support.citrix.com/article/CTX140208
#         Driver Source https://www.catalog.update.microsoft.com/Search.aspx?q=HP%20LaserJet%202800
#
#####################################################################################################
 
If (-not (Test-Path C:\Driver\HPLJ2800Series -PathType Container)) {
   New-Item C:\Driver\HPLJ2800Series -ItemType directory
   }
 
 
$url = "http://download.windowsupdate.com/msdownload/update/driver/drvs/2011/07/4753_fc148f3df197a4c5cf20bd6a8b337b444037655f.cab"
$output = "C:\Driver\4753_fc148f3df197a4c5cf20bd6a8b337b444037655f.cab"
$start_time = Get-Date
 
Invoke-WebRequest -Uri $url -OutFile $output
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
 
Set-Location -Path C:\Driver
& expand.exe 4753_fc148f3df197a4c5cf20bd6a8b337b444037655f.cab -F:* C:\Driver\HPLJ2800Series
 
Write-Host "Folder found - Install HP 2800 Series PS Driver"
& pnputil.exe -a "C:\Driver\HPLJ2800Series\prnhp002.inf"
Write-Host "Add Driver to local PrintServer."
Add-PrinterDriver -Name "HP Color LaserJet 2800 Series PS"
Write-Host "Clean-up"
Set-Location -Path $PSScriptRoot
Remove-Item –path  C:\Driver -Recurse
Write-Host "All done!"

