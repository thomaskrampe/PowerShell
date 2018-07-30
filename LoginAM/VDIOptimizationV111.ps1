# ===========================================================================================================
#
# Title:              Windows 8 and Server 2012 VDI Optimization Script
# Author:             Thomas Krampe - t.krampe@loginconsultants.com
#
# Created:            10.06.2014
#
# Version:            1.1.1
#
# Special thanks to : Pablo Legorreta for creating big parts in VBS,
#                     Steven Krueger, William Elvington,
#                     Jonathan Bennett (AutoITScript) for creating a wonderful optimizer tool
#                     and to Jeff Stokes (MSFT) for creating the original baseline script for Windows 7
#
# Purpose:            The following script will prepare and optimize a Windows 8 or Server 2012
#                     static image for VDI deployment based on MSFT and Citrix recommendations.
#
# Requirements:       Administrative Privileges, Registry backup (Just in case) and of course commonsense ;)
#                     After running that script you should restart the system !!!!
#
#                     THIS SCRIPT IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, 
#                     INCLUDING ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR 
#                     NON-INFRINGEMENT. THOMAS KRAMPE, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS 
#                     OR OMISSIONS CONTAINED HEREIN, NOR FOR DIRECT, INCIDENTAL, CONSEQUENTIAL OR ANY OTHER 
#                     DAMAGES RESULTING FROM THE FURNISHING, PERFORMANCE, OR USE OF THIS SCRIPT, EVEN 
#                     IF THOMAS KRAMPE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES IN ADVANCE.
#
# License:            Creative Commons CC BY-NC-SA 4.0
#                     http://creativecommons.org/licenses/by-nc-sa/4.0/
# 
# ===========================================================================================================

# ===================================================
# Variables
# ===================================================

$ErrorActionPreference = 'SilentlyContinue'
$OSName = (Get-WmiObject Win32_OperatingSystem).Caption
$AMEnvName = (Get-Item env:am_env_name).Value

# ===================================================
# Package Settings for Automation Machine
# Get Automation Machine today
# http://www.getautomationmachine.com/en/download
# ===================================================

If($AMEnvName) {
	$Disable_Aero = (Get-Item env:Disable_Aero).Value
	$Disable_BranchCache = (Get-Item env:Disable_BranchCache).Value
	$Disable_EFS = (Get-Item env:Disable_EFS).Value
	$Disable_iSCSI = (Get-Item env:Disable_iSCSI).Value
	$Disable_MachPass = (Get-Item env:Disable_MachPass).Value
	$Disable_Search = (Get-Item env:Disable_Search).Value
    $Clear_EVT = (Get-Item env:Clear_EVT).Value
    $Move_PF = (Get-Item env:Move_PF).Value
    $PF_Drive = (Get-Item env:PF_Drive).Value
    $PF_Min = (Get-Item env:PF_Min).Value
    $PF_Max = (Get-Item env:PF_Max).Value
    }

# ===================================================
# Settings for the use without Automation Machine
# Simply uncomment the settings you want to use
# and change the values to your own needs.
# ===================================================

# $Disable_Aero = $True
# $Disable_BranchCache = $True
# $Disable_EFS = $True
# $Disable_iSCSI = $True
# $Disable_MachPass = $True
# $Disable_Search = $True
# $Clear_EVT = $True
# $Move_PF = $True
# $PF_Drive = "D:\"
# $PF_Min = "4096"
# $PF_Max = "4096"

# ===================================================
# Let the Voodoo begin
# ===================================================

# ===================================================
# Service Settings
# ===================================================

# Disable Themes Service
If($Disable_Aero -eq $true) {Set-Service Themes -StartupType Disabled}

# Disable BranchCache Service
If($Disable_BranchCache -eq $true) {Set-Service PeerDistSvc -StartupType Disabled}

# Disable Encrypting File System Service
If($Disable_EFS -eq $true) {Set-Service EFS -StartupType Disabled}

# Disable Microsoft iSCSI Initiator Service
If($Disable_iSCSI -eq $true) {Set-Service msiscsi -StartupType Disabled}

# Disable Microsoft iSCSI Initiator Service
If($Disable_iSCSI -eq $true) {Set-Service msiscsi -StartupType Disabled}

# Disable Machine Account Password Changes
If($Disable_MachPass -eq $true) {Set-ItemProperty -Name DisablePasswordChange -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Netlogon\Parameters' -Type DWord -Value 0x00000001}

# Disable Windows Search Service
If($Disable_Search -eq $true) {Stop-Service WSearch; Set-Service WSearch -StartupType Disabled}

# Disable Application Layer Gateway Service
Set-Service ALG -StartupType Disabled

# Disable Background Intelligent Transfer Service
Set-Service BITS -StartupType Disabled

# Disable Bitlocker Drive Encryption Service
Set-Service BDESVC -StartupType Disabled

# Disable Block Level Backup Engine Service
Set-Service wbengine -StartupType Disabled

# Disable Bluetooth Support Service
Set-Service bthserv -StartupType Disabled

# Disable Computer Browser Service
Set-Service Browser -StartupType Disabled

# Disable Device Association Service
Set-Service DeviceAssociationService -StartupType Disabled

# Disable Device Setup Manager Service
Set-Service DsmSvc -StartupType Disabled

# Disable Diagnostic Policy Services
Set-Service DPS -StartupType Disabled
Set-Service WdiServiceHost -StartupType Disabled
Set-Service WdiSystemHost -StartupType Disabled

# Disable Distributed Link Tracking Client Service
Set-Service TrkWks -StartupType Disabled

# Disable Family Safety Service
Set-Service WPCSvc -StartupType Disabled

# Disable Fax Service
Set-Service Fax -StartupType Disabled

# Disable Function Discovery Resource Publication Service
Set-Service FDResPub -StartupType Disabled

# Disable HomeGroup Listener Service
Set-Service HomeGroupListener -StartupType Disabled

# Disable HomeGroup Provider Service
Set-Service HomeGroupProvider -StartupType Disabled

# Disable Microsoft Software Shadow Copy Provider Service
Set-Service swprv -StartupType Disabled

# Set Network List Service to Auto
Set-Service netprofm -StartupType Auto

# Disable Offline Files
Set-Service CscService -StartupType Disabled

# Disable Optimize Drives Service
Disable-ScheduledTask -Taskname ScheduledDefrag -TaskPath 'microsoft\windows\defrag' | Out-Null
Set-Service defragsvc -StartupType Disabled

# Disable Secure Socket Tunneling Protocol Service
Set-Service SstpSvc -StartupType Disabled

# Disable Security Center
Set-Service wscsvc -StartupType Disabled

# Disable Sensor Monitoring Service
Set-Service SensrSvc -StartupType Disabled

# Disable Shell Hardware Detection Service
Set-Service ShellHWDetection -StartupType Disabled

# Disable SNMP Trap Service
Set-Service SNMPTRAP -StartupType Disabled

# Disable SSDP Discovery Service
Stop-Service SSDPSRV
Set-Service SSDPSRV -StartupType Disabled

# Disable SuperFetch
Set-Service SysMain -StartupType Disabled

# Disable SuperFetch
Set-Service SysMain -StartupType Disabled

# Disable Telephony Service
Set-Service TapiSrv -StartupType Disabled

# Disable UPnP Device Host Service
Set-Service upnphost -StartupType Disabled

# Disable Volume Shadow Copy Service
Set-Service VSS -StartupType Disabled

# Disable Windows Backup Service
Set-Service SDRSVC -StartupType Disabled

# Disable Windows Color System Service
Set-Service WcsPlugInService -StartupType Disabled

# Disable Windows Connect Now - Config Registrar Service
Set-Service wcncsvc -StartupType Disabled

# Disable Windows Defender Service
Set-Service WinDefend -StartupType Disabled

# Disable Windows Error Reporting Service
Set-Service WerSvc -StartupType Disabled

# Disable Windows Media Player Network Sharing Service
Set-Service WMPNetworkSvc -StartupType Disabled

# Disable Windows Updates
Set-Service wuauserv -StartupType Disabled

# Disable WLAN AutoConfig Service
Set-Service Wlansvc -StartupType Disabled

# Disable WWAN AutoConfig Service
Set-Service WwanSvc -StartupType Disabled

# ===================================================
# Computer Settings
# ===================================================

# Disable Action Center
Set-ItemProperty -Name HideSCAHealth -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Type DWord -Value 0x00000001

# Optimize Processor Resource Scheduling
Set-ItemProperty -Name Win32PrioritySeparation -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' -Type DWord -Value 0x00000026

# Disable TCP/IP / Large Send Offload
Set-ItemProperty -Name DisableTaskOffload -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters' -Type DWord -Value 0x00000001

# Disable hibernate
Start-Process 'powercfg.exe' -Verb runAs -ArgumentList '/h off'

# Disable Hard disk timeouts
Start-Process 'powercfg.exe' -Verb runAs -ArgumentList '/SETACVALUEINDEX 381b4222-f694-41f0-9685-ff5bb260df2e 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0'
Start-Process 'powercfg.exe' -Verb runAs -ArgumentList '/SETDCVALUEINDEX 381b4222-f694-41f0-9685-ff5bb260df2e 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0'

# Break out Windows Management Instrumentation Service
Start-Process 'sc.exe' -Verb runAs -ArgumentList 'config winmgmt group="COM Infrastructure"'
Start-Process 'winmgmt.exe' -Verb runAs -ArgumentList '/standalonehost'

# Disable NTFS Last Access Timestamps
Start-Process 'FSUTIL' -Verb runAs -ArgumentList 'behavior set disablelastaccess 1'

# Disable memory dumps
Set-ItemProperty -Name CrashDumpEnabled -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -Type DWord -Value 0x00000000
Set-ItemProperty -Name LogEvent -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -Type DWord -Value 0x00000000
Set-ItemProperty -Name SendAlert -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -Type DWord -Value 0x00000000
Set-ItemProperty -Name AutoReboot -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl' -Type DWord -Value 0x00000001

# Increase service startup timeouts
Set-ItemProperty -Name ServicesPipeTimeout -Path 'HKLM:\SYSTEM\CurrentControlSet\Control' -Type DWord -Value 0x0002bf20

# Increase Disk I/O Timeout to 200 seconds
Set-ItemProperty -Name TimeOutValue -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Disk' -Type DWord -Value 0x000000C8

# Set PopUp Error Mode to "Neither"
Set-ItemProperty -Name ErrorMode -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Windows' -Type DWord -Value 2

# Configure Eventlogs
Limit-EventLog -LogName Application -MaximumSize 2048KB -OverflowAction OverwriteAsNeeded
Limit-EventLog -LogName Security -MaximumSize 2048KB -OverflowAction OverwriteAsNeeded
Limit-EventLog -LogName System -MaximumSize 2048KB -OverflowAction OverwriteAsNeeded
Limit-EventLog -LogName HardwareEvents -MaximumSize 2048KB -OverflowAction OverwriteAsNeeded
Limit-EventLog -LogName 'Internet Explorer' -MaximumSize 2048KB -OverflowAction OverwriteAsNeeded
Limit-EventLog -LogName 'Key Management Service' -MaximumSize 2048KB -OverflowAction OverwriteAsNeeded
Limit-EventLog -LogName 'Remote Lab Exchange Service' -MaximumSize 2048KB -OverflowAction OverwriteAsNeeded
Limit-EventLog -LogName 'Windows Assessment Services Client' -MaximumSize 2048KB -OverflowAction OverwriteAsNeeded
Limit-EventLog -LogName 'Windows PowerShell' -MaximumSize 2048KB -OverflowAction OverwriteAsNeeded

Set-ItemProperty -Name Retention -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\eventlog\Application' -Type DWord -Value 0x00000000
Set-ItemProperty -Name Retention -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\eventlog\Security' -Type DWord -Value 0x00000000
Set-ItemProperty -Name Retention -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\eventlog\System' -Type DWord -Value 0x00000000

# Clear Eventlogs
If($Clear_EVT -eq $true) {
    Clear-EventLog -LogName Application
    Clear-EventLog -LogName Security
    Clear-EventLog -LogName System
    Clear-EventLog -LogName HardwareEvents
    Clear-EventLog -LogName 'Internet Explorer'
    Clear-EventLog -LogName 'Key Management Service'
    Clear-EventLog -LogName 'Remote Lab Exchange Service'
    Clear-EventLog -LogName 'Windows Assessment Services Client'
    Clear-EventLog -LogName 'Windows PowerShell'
    }

# Move Pagefile and set fixed size
If($Move_PF -eq $true) {
    $PF_Path = $PF_Drive + "pagefile.sys"
    $CurrentPageFile = gwmi -Query "select * from Win32_PageFileSetting where name='c:\\pagefile.sys'" -EnableAllPrivileges
    If($CurrentPageFile){$CurrentPageFile.Delete()}
    swmi Win32_PageFileSetting -Arguments @{Name=$PF_Path; InitialSize=$PF_Min; MaximumSize=$PF_Max} | Out-Null 
    }

# Disable Useless Scheduled Tasks
$taskcheck01 = Get-ScheduledTask -TaskName "AitAgent" -ErrorAction SilentlyContinue
IF($taskcheck01) {Disable-ScheduledTask -Taskname AitAgent -TaskPath 'microsoft\windows\Application Experience' | Out-Null}

$taskcheck02 = Get-ScheduledTask -TaskName "ProgramDataUpdater" -ErrorAction SilentlyContinue
IF($taskcheck02) {Disable-ScheduledTask -Taskname ProgramDataUpdater -TaskPath 'microsoft\windows\Application Experience' | Out-Null}

$taskcheck03 = Get-ScheduledTask -TaskName "StartupAppTask" -ErrorAction SilentlyContinue
IF($taskcheck03) {Disable-ScheduledTask -Taskname StartupAppTask -TaskPath 'microsoft\windows\Application Experience' | Out-Null}

$taskcheck04 = Get-ScheduledTask -TaskName "Proxy" -ErrorAction SilentlyContinue
IF($taskcheck04) {Disable-ScheduledTask -Taskname Proxy -TaskPath 'microsoft\windows\Autochk' | Out-Null}

$taskcheck05 = Get-ScheduledTask -TaskName "UninstallDeviceTask" -ErrorAction SilentlyContinue
IF($taskcheck05) {Disable-ScheduledTask -Taskname UninstallDeviceTask -TaskPath 'microsoft\windows\Bluetooth' | Out-Null}

$taskcheck06 = Get-ScheduledTask -TaskName "BthSQM" -ErrorAction SilentlyContinue
IF($taskcheck06) {Disable-ScheduledTask -Taskname BthSQM -TaskPath 'microsoft\windows\Customer Experience Improvement Program' | Out-Null}

$taskcheck07 = Get-ScheduledTask -TaskName "Consolidator" -ErrorAction SilentlyContinue
IF($taskcheck07) {Disable-ScheduledTask -Taskname Consolidator -TaskPath 'microsoft\windows\Customer Experience Improvement Program' | Out-Null}

$taskcheck08 = Get-ScheduledTask -TaskName "KernelCeipTask" -ErrorAction SilentlyContinue
IF($taskcheck08) {Disable-ScheduledTask -Taskname KernelCeipTask -TaskPath 'microsoft\windows\Customer Experience Improvement Program' | Out-Null}

$taskcheck09 = Get-ScheduledTask -TaskName "Uploader" -ErrorAction SilentlyContinue
IF($taskcheck09) {Disable-ScheduledTask -Taskname Uploader -TaskPath 'microsoft\windows\Customer Experience Improvement Program' | Out-Null}

$taskcheck10 = Get-ScheduledTask -TaskName "UsbCeip" -ErrorAction SilentlyContinue
IF($taskcheck10) {Disable-ScheduledTask -Taskname UsbCeip -TaskPath 'microsoft\windows\Customer Experience Improvement Program' | Out-Null}

$taskcheck11 = Get-ScheduledTask -TaskName "Scheduled" -ErrorAction SilentlyContinue
IF($taskcheck11) {Disable-ScheduledTask -Taskname Scheduled -TaskPath 'microsoft\windows\Diagnosis' | Out-Null}

$taskcheck12 = Get-ScheduledTask -TaskName "Microsoft-Windows-DiskDiagnosticDataCollector" -ErrorAction SilentlyContinue
IF($taskcheck12) {Disable-ScheduledTask -Taskname Microsoft-Windows-DiskDiagnosticDataCollector -TaskPath 'microsoft\windows\DiskDiagnostic' | Out-Null}

$taskcheck13 = Get-ScheduledTask -TaskName "Microsoft-Windows-DiskDiagnosticResolver" -ErrorAction SilentlyContinue
IF($taskcheck13) {Disable-ScheduledTask -Taskname Microsoft-Windows-DiskDiagnosticResolver -TaskPath 'microsoft\windows\DiskDiagnostic' | Out-Null}

$taskcheck14 = Get-ScheduledTask -TaskName "WinSAT" -ErrorAction SilentlyContinue
IF($taskcheck14) {Disable-ScheduledTask -Taskname WinSAT -TaskPath 'microsoft\windows\Maintenance' | Out-Null}

$taskcheck15 = Get-ScheduledTask -TaskName "HotStart" -ErrorAction SilentlyContinue
IF($taskcheck15) {Disable-ScheduledTask -Taskname HotStart -TaskPath 'microsoft\windows\MobilePC' | Out-Null}

$taskcheck16 = Get-ScheduledTask -TaskName "AnalyzeSystem" -ErrorAction SilentlyContinue
IF($taskcheck16) {Disable-ScheduledTask -Taskname AnalyzeSystem -TaskPath 'microsoft\windows\Power Efficiency Diagnostics' | Out-Null}

$taskcheck17 = Get-ScheduledTask -TaskName "RacTask" -ErrorAction SilentlyContinue
IF($taskcheck17) {Disable-ScheduledTask -Taskname RacTask -TaskPath 'microsoft\windows\RAC' | Out-Null}

$taskcheck18 = Get-ScheduledTask -TaskName "MobilityManager" -ErrorAction SilentlyContinue
IF($taskcheck18) {Disable-ScheduledTask -Taskname MobilityManager -TaskPath 'microsoft\windows\Ras' | Out-Null}

$taskcheck19 = Get-ScheduledTask -TaskName "RegIdleBackup" -ErrorAction SilentlyContinue
IF($taskcheck19) {Disable-ScheduledTask -Taskname RegIdleBackup -TaskPath 'microsoft\windows\Registry' | Out-Null}

$taskcheck20 = Get-ScheduledTask -TaskName "FamilySafetyMonitor" -ErrorAction SilentlyContinue
IF($taskcheck20) {Disable-ScheduledTask -Taskname FamilySafetyMonitor -TaskPath 'microsoft\windows\Shell' | Out-Null}

$taskcheck21 = Get-ScheduledTask -TaskName "FamilySafetyRefresh" -ErrorAction SilentlyContinue
IF($taskcheck21) {Disable-ScheduledTask -Taskname FamilySafetyRefresh -TaskPath 'microsoft\windows\Shell' | Out-Null}

$taskcheck22 = Get-ScheduledTask -TaskName "AutoWake" -ErrorAction SilentlyContinue
IF($taskcheck22) {Disable-ScheduledTask -Taskname AutoWake -TaskPath 'microsoft\windows\SideShow' | Out-Null}

$taskcheck23 = Get-ScheduledTask -TaskName "GadgetManager" -ErrorAction SilentlyContinue
IF($taskcheck23) {Disable-ScheduledTask -Taskname GadgetManager -TaskPath 'microsoft\windows\SideShow' | Out-Null}

$taskcheck24 = Get-ScheduledTask -TaskName "SessionAgent" -ErrorAction SilentlyContinue
IF($taskcheck24) {Disable-ScheduledTask -Taskname SessionAgent -TaskPath 'microsoft\windows\SideShow' | Out-Null}

$taskcheck25 = Get-ScheduledTask -TaskName "SystemDataProviders" -ErrorAction SilentlyContinue
IF($taskcheck25) {Disable-ScheduledTask -Taskname SystemDataProviders -TaskPath 'microsoft\windows\SideShow' | Out-Null}

$taskcheck26 = Get-ScheduledTask -TaskName "UPnPHostConfig" -ErrorAction SilentlyContinue
IF($taskcheck26) {Disable-ScheduledTask -Taskname UPnPHostConfig -TaskPath 'microsoft\windows\UPnP' | Out-Null}

$taskcheck27 = Get-ScheduledTask -TaskName "ResolutionHost" -ErrorAction SilentlyContinue
IF($taskcheck27) {Disable-ScheduledTask -Taskname ResolutionHost -TaskPath 'microsoft\windows\WDI' | Out-Null}

$taskcheck28 = Get-ScheduledTask -TaskName "BfeOnServiceStartTypeChange" -ErrorAction SilentlyContinue
IF($taskcheck28) {Disable-ScheduledTask -Taskname BfeOnServiceStartTypeChange -TaskPath 'microsoft\windows\Windows Filtering Platform' | Out-Null}

$taskcheck29 = Get-ScheduledTask -TaskName "UpdateLibrary" -ErrorAction SilentlyContinue
IF($taskcheck29) {Disable-ScheduledTask -Taskname UpdateLibrary -TaskPath 'microsoft\windows\Windows Media Sharing' | Out-Null}

# Disable bootlog and boot animation
Start-Process 'bcdedit.exe' -Verb runAs -ArgumentList '/set {default} bootlog no' | Out-Null
Start-Process 'bcdedit.exe' -Verb runAs -ArgumentList '/set {default} quietboot yes' | Out-Null

# Disable Data Execution Prevention
Start-Process 'bcdedit.exe' -Verb runAs -ArgumentList '/set nx AlwaysOff' | Out-Null

# Disable Startup Repair option
Start-Process 'bcdedit.exe' -Verb runAs -ArgumentList '/set {default} bootstatuspolicy ignoreallfailures' | Out-Null

# Disable UAC secure desktop prompt
Set-ItemProperty -Name PromptOnSecureDesktop -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System' -Type DWord -Value 0x00000000

# Disable New Network dialog
Set-ItemProperty -Name NewNetworkWindowOff -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Network' -Type String -Value 0

# Disable AutoUpdate of drivers from WU
Set-ItemProperty -Name searchorderConfig -Path 'HKLM:\Software\Policies\Microsoft\Windows\DriverSearching' -Type DWord -Value 0x00000000

# Disable IE First Run Wizard and RSS Feeds
Set-ItemProperty -Name DisableFirstRunCustomize -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Internet Explorer\Main' -Type DWord -Value 0x00000001

# Disable the ability to clear the paging file during shutdown
Set-ItemProperty -Name ClearPageFileAtShutdown -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\SessionManager\Memory Management' -Type DWord -Value 0x00000000

# Disable Internet Explorer Enhanced Security Enhanced
Set-ItemProperty -Name IsInstalled -Path 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A7-37EF-4b3f-8CFC-4F3A74704073' -Type DWord -Value 0x00000000
Set-ItemProperty -Name IsInstalled -Path 'HKLM:\SOFTWARE\Microsoft\Active Setup\Installed Components\{A509B1A8-37EF-4b3f-8CFC-4F3A74704073' -Type DWord -Value 0x00000000

# Disables Background Layout Service
Set-ItemProperty -Name EnabledAutoLayout -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\OptimalLayout' -Type DWord -Value 0x00000000

# Disables CIFS Change Notifications
Set-ItemProperty -Name NoRemoteRecursiveEvents -Path 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Type DWord -Value 0x00000001

# Set Power Saving Scheme to High Performance
Start-Process 'powercfg.exe' -Verb runAs -ArgumentList '-s 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c'

# Set Recovery Dump to Small
Start-Process 'wmic.exe' -Verb runAs -ArgumentList 'recoveros set DebugInfoType = 3'

# Perform a disk cleanup (Windows 8 only)
# Automate by creating the reg checks corresponding to "cleanmgr /sageset:100" so we can use "sagerun:100"
If ($OSName -contains '*Windows 8*') { 
    Set-ItemProperty -Name StateFlags0100 -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Active Setup Temp Folders' -Type DWord -Value 0x00000002
    Set-ItemProperty -Name StateFlags0100 -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Downloaded Program Files' -Type DWord -Value 0x00000002
    Set-ItemProperty -Name StateFlags0100 -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Internet Cache Files' -Type DWord -Value 0x00000002
    Set-ItemProperty -Name StateFlags0100 -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Memory Dump Files' -Type DWord -Value 0x00000002
    Set-ItemProperty -Name StateFlags0100 -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Offline Pages Files' -Type DWord -Value 0x00000002
    Set-ItemProperty -Name StateFlags0100 -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Old ChkDsk Files' -Type DWord -Value 0x00000002
    Set-ItemProperty -Name StateFlags0100 -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Previous Installations' -Type DWord -Value 0x00000000
    Set-ItemProperty -Name StateFlags0100 -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Recycle Bin' -Type DWord -Value 0x00000002
    Set-ItemProperty -Name StateFlags0100 -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Setup Log Files' -Type DWord -Value 0x00000002
    Set-ItemProperty -Name StateFlags0100 -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error memory dump files' -Type DWord -Value 0x00000002
    Set-ItemProperty -Name StateFlags0100 -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\System error minidump files' -Type DWord -Value 0x00000002
    Set-ItemProperty -Name StateFlags0100 -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Files' -Type DWord -Value 0x00000002
    Set-ItemProperty -Name StateFlags0100 -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Temporary Setup Files' -Type DWord -Value 0x00000002
    Set-ItemProperty -Name StateFlags0100 -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Thumbnail Cache' -Type DWord -Value 0x00000002
    Set-ItemProperty -Name StateFlags0100 -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Upgrade Discarded Files' -Type DWord -Value 0x00000000
    Set-ItemProperty -Name StateFlags0100 -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Archive Files' -Type DWord -Value 0x00000002
    Set-ItemProperty -Name StateFlags0100 -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting Queue Files' -Type DWord -Value 0x00000002
    Set-ItemProperty -Name StateFlags0100 -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting System Archive Files' -Type DWord -Value 0x00000002
    Set-ItemProperty -Name StateFlags0100 -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Error Reporting System Queue Files' -Type DWord -Value 0x00000002
    Set-ItemProperty -Name StateFlags0100 -Path 'HKLM:\Software\Microsoft\Windows\CurrentVersion\Explorer\VolumeCaches\Windows Upgrade Log Files' -Type DWord -Value 0x00000002
    Start-Process 'cleanmgr.exe' -Verb runAs -ArgumentList '/sagerun:100 | out-Null'
    }

# Disable IPv6
Set-ItemProperty -Name DisabledComponents -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters' -Type DWord -Value 0x000000ff

# Do not open Server Manager at Login (Machine)
Set-ItemProperty -Name DoNotOpenServerManagerAtLogon -Path 'HKLM:\SOFTWARE\Microsoft\ServerManager' -Type DWord -Value 0x00000001

# ===================================================
# User Settings
# ===================================================

# Do not open Server Manager at Login (User)
Set-ItemProperty -Name DoNotOpenServerManagerAtLogon -Path 'HKCU:\SOFTWARE\Microsoft\ServerManager' -Type DWord -Value 0x00000001

# Reduce menu show delay
Set-ItemProperty -Name MenuShowDelay -Path 'HKCU:\Control Panel\Desktop' -Type DWord -Value 0x00000000

# Disable cursor blink
Set-ItemProperty -Name DisableCursorBlink -Path 'HKCU:\Control Panel\Desktop' -Type DWord -Value 0x00000001
Set-ItemProperty -Name CursorBlinkRate -Path 'HKCU:\Control Panel\Desktop' -Type String -Value '-1'

# Force off-screen composition in IE
Set-ItemProperty -Name 'Force Offscreen Composition' -Path 'HKCU:\Software\Microsoft\Internet Explorer\Main' -Type DWord -Value 0x00000001

# Disable screensavers
Set-ItemProperty -Name ScreenSaveActive -Path 'HKCU:\Software\Policies\Microsoft\Windows\Control Panel\Desktop' -Type DWord -Value 0x00000000
Set-ItemProperty -Name ScreenSaveActive -Path 'HKCU:\Control Panel\Desktop' -Type DWord -Value 0x00000000

# Don't show window minimize/maximize animations
Set-ItemProperty -Name MinAnimate -Path 'HKCU:\Control Panel\Desktop\WindowMetrics' -Type DWord -Value 0x00000000

# Don't show window contents when dragging
Set-ItemProperty -Name DragFullWindows -Path 'HKCU:\Control Panel\Desktop' -Type DWord -Value 0x00000000

# Disable font smoothing
Set-ItemProperty -Name FontSmoothing -Path 'HKCU:\Control Panel\Desktop' -Type DWord -Value 0x00000000

# Disable most other visual effects
Set-ItemProperty -Name VisualFXSetting -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Type DWord -Value 0x00000003
Set-ItemProperty -Name ListviewAlphaSelect -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Type DWord -Value 0x00000000
Set-ItemProperty -Name TaskbarAnimations -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Type DWord -Value 0x00000000
Set-ItemProperty -Name ListviewWatermark -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Type DWord -Value 0x00000000
Set-ItemProperty -Name ListviewShadow -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Type DWord -Value 0x00000000

# Disable Action Center
Set-ItemProperty -Name HideSCAHealth -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Type DWord -Value 0x00000001

# Disable IE Persistent Cach
Set-ItemProperty -Name Persistent -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Internet Settings\Cache' -Type DWord -Value 0x00000000
Set-ItemProperty -Name SyncStatus -Path 'HKCU:\Software\Microsoft\Feeds' -Type DWord -Value 0x00000000

# ===========================================================================================================
# End of Voodoo
# ===========================================================================================================
Write-Host "Optimization done - please reboot!"