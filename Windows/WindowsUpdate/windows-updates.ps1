#Requires -RunAsAdministrator
#Requires -Version 5.1

<#
.SYNOPSIS
    Install Windows Updates

.DESCRIPTION
    Install Windows Updates using a server list

.EXAMPLE
    Output:
    -----------------------------------------------------------------------------------------------------------------------
    PS C:\Temp> C:\Temp\windows-updates.ps1
    Starting Windows Updates on server1.demo.local
        Windows Malicious Software Removal Tool x64 - v5.98 (KB890830)
        2022-02 Cumulative Update Preview for .NET Framework 3.5, 4.7.2 and 4.8 for Windows Server 2019 for x64 (KB5011267)
        Security Intelligence Update for Microsoft Defender Antivirus - KB2267602 (Version 1.359.1358.0)
        2022-02 Cumulative Update for Windows Server 2019 (1809) for x64-based Systems (KB5010351)
  
    Installing 4 updates.
    True
    Reboot required on server1.demo.local
    -----------------------------------------------------------------------------------------------------------------------

.PARAMETER NoRestart
    Suppress restart

.PARAMETER LocalPW
    Ask for credentials (don't use saved credentials in a password file)

.LINK
    https://github.com/thomaskrampe/PowerShell/tree/master/Windows/WindowsUpdate

.NOTES
    Author        : Thomas Krampe | t.krampe@loginconsultants.de
    Version       : 0.1
    Creation date : 04.03.2022 | v0.1 | Initial script
                    05.03.2022 | v1.0 | first release 
    Last change   : 06.03.2022 | v1.1 | Add NoRestart parameter

    NOTICE
    THIS SCRIPT IS PROVIDED “AS IS” WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING 
    ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT. 
    THOMAS KRAMPE, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS OR OMISSIONS CONTAINED HEREIN,
    NOR FOR DIRECT, INCIDENTAL, CONSEQUENTIAL OR ANY OTHER DAMAGES RESULTING FROM THE FURNISHING, 
    PERFORMANCE, OR USE OF THIS SCRIPT, EVEN IF THOMAS KRAMPE HAS BEEN ADVISED OF THE POSSIBILITY 
    OF SUCH DAMAGES IN ADVANCE.
#>

param
(
    # Turn automatic reboot off
    [Parameter][Switch]$NoRestart,
    [Parameter][switch]$LocalPW
)

# Change your path and file name here
$ServersListPath = ""
$PasswordFilePath = ""

if (-not($ServersListPath)) {
    $ServersListPath = "$PSSCriptRoot\servers.txt"
}

if (-not($PasswordFilePath)) {
    $PasswordFilePath = "$PSScriptRoot\password.txt"
}

# Read servers.txt content
If (-not(Test-Path -Path $ServersListPath -PathType Leaf )) {
    Write-Host "Servers file doesn't exist, exit script." -ForegroundColor Red
    exit 1
} else {
    $servers = Get-Content $ServersListPath
}

# Authentication
if ($LocalPW) {
    $Credential = Get-Credential
} else {
    $HexPass = Get-Content $PasswordFilePath
    $Credential = New-Object -TypeName PSCredential -ArgumentList "administrator@demo.local", ($HexPass | ConvertTo-SecureString)
}

# Start the main loop
ForEach ($server in $servers) {

    # Get available updates for target server
    write-host "Starting Windows Updates on $server"
    
    try {
        $up = Invoke-Command -ComputerName $server -ScriptBlock {Start-WUScan -SearchCriteria "Type='Software' AND IsInstalled=0"} -Credential $Credential
    }
    catch {
        throw $_.Exception.Message
    }
    
    if ($up) { 
        # Installing updates on target server
        $upc = $up.count
        write-host "Found $upc updates." -ForegroundColor Green
        
        for ($num = 0 ; $num -le $upc ; $num++){
            write-host "    "$up[$num].Title
        }

        $cs = New-CimSession -ComputerName $server -Credential $Credential
        Install-WUUpdates -Updates $up -CimSession $cs
        
        $rb = Invoke-Command -ComputerName $server -ScriptBlock {Get-WUIsPendingReboot} -Credential $Credential
        
        if ($rb -eq $true) {
            write-host "Reboot required on $server." -ForegroundColor Yellow
            
            # Reboot server
            if (-not($NoRestart)) {
                write-host "Restart initiated on $server." -ForegroundColor Yellow
                Restart-Computer -ComputerName $server -Credential $Credential -force
            } else {
                write-host "Automatic restart prevented with -NoRestart switch. Please restart the targets manually." -ForegroundColor Red
            }
        }
        else { 
            write-host "No reboot required on $server" -ForegroundColor Green
        }
    } 
    else {
        write-host "No Updates available for $server" -ForegroundColor Green
    } 
}
