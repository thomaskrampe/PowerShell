# ------------------------------------------------------
# Prepare and initialize new Machine for AM deployment
#
# Thomas Krampe - t.krampe@loginconsultants.com
# (c) 2015 Login Consultants Germany GmbH
# ------------------------------------------------------

# Variables 
$AMShare = "\\lab-am-01\am$\ea7a74ea-8059-4878-907a-964c7e745cea"

# Enable Remote Admin in Windows Firewall
netsh firewall set service type=REMOTEADMIN mode=ENABLE

#Allow ICMPv4 in Windows Firewall
New-NetFirewallRule -Name Allow_ICMPv4 -DisplayName "Allow ICMPv4" -Protocol ICMPv4 -Enable True -Profile Any -Action Allow

# Set Execution Policy
Set-ExecutionPolicy Bypass

# Enable CredSSP for PS remoting
Enable-WSManCredSSP -Role Server -Force
Enable-WSManCredSSP -Role Client -DelegateComputer * -Force

# Make sure Remote Registry Service is running
Get-Service RemoteRegistry | where {$_.status -eq "Stopped"} | start-service -PassThru

# Initialize AM
If (Test-Path $AMShare) {
    & $AMShare\Initialize-AM.ps1
    }
Else {
    Write-Host "Someting went wrong! Environment not available."
}

