# Register McliPSSnapIn
$Path =(Get-Item 'env:ProgramFiles').Value + "\Citrix\Provisioning Services Console\McliPSSnapIn.dll"
& "$env:SystemRoot\Microsoft.NET\Framework64\v2.0.50727\installutil.exe" “$Path”
write-host "McliPSSnapIn registered."

# Import PSSnapIn
add-PSSnapIn mclipssnapin

# Sometimes the SOAP Service stop working. Just check this and restart the service if neccessary 
If ((gsv soapserver).Status -ne "Running")  {
    Restart-Service soapserver
    Write-Host "soapservcer restartet!"
    }
Else {
	Write-Host "soapserver is running."
}