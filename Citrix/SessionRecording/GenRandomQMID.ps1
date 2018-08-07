<#
.SYNOPSIS
    Generate Random QMID for Citrix Session Recording Agent on PVS or MCS images

.DESCRIPTION
    When Machine Creation Services (MCS) or Provisioning Services (PVS) creates multiple VDAs with 
    the configured master image and Microsoft Message Queuing (MSMQ) installed, those VDAs can have 
    the same QMId under certain conditions.

    Ensure that the execution policy is set to RemoteSigned or Unrestricted in PowerShell.
    Set-ExecutionPolicy RemoteSigned

    Create a scheduled task, set the trigger as on system startup, and run with the SYSTEM account on 
    the PVS or MCS master image machine. Add the command as a startup task.

    eg. powershell.exe -file C:\GenRandomQMID.ps1

.NOTES
     Author        : Thomas Krampe | t.krampe@loginconsultants.de
     Version       : 1.0
     Creation date : 06.08.2018 | v0.1 | Initial script for Athora
     

    NOTICE
    THIS SCRIPT IS PROVIDED “AS IS” WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING 
    ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT. 
    LOGIN CONSULTANTS, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS OR OMISSIONS CONTAINED HEREIN,
    NOR FOR DIRECT, INCIDENTAL, CONSEQUENTIAL OR ANY OTHER DAMAGES RESULTING FROM THE FURNISHING, 
    PERFORMANCE, OR USE OF THIS SCRIPT, EVEN IF THOMAS KRAMPE HAS BEEN ADVISED OF THE POSSIBILITY 
    OF SUCH DAMAGES IN ADVANCE.
#>

# Remove old QMId from registry and set SysPrep flag for MSMQ
Remove-Itemproperty -Path HKLM:Software\Microsoft\MSMQ\Parameters\MachineCache -Name QMId -Force
Set-ItemProperty -Path HKLM:Software\Microsoft\MSMQ\Parameters -Name "SysPrep" -Type DWord -Value 1

# Get dependent services
$depServices = Get-Service -name MSMQ -dependentservices | Select -Property Name

# Restart MSMQ to get a new QMId
Restart-Service -force MSMQ

# Start dependent services
if ($depServices -ne $null) {
    foreach ($depService in $depServices) {
        $startMode = Get-WmiObject win32_service -filter "NAME = '$($depService.Name)'" | Select -Property StartMode
        if ($startMode.StartMode -eq "Auto") {
            Start-Service $depService.Name
        }
    }
}