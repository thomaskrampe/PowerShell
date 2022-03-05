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
.LINK
    https://github.com/thomaskrampe/PowerShell/tree/master/Windows/WindowsUpdate
         
.NOTES
     Author        : Thomas Krampe | t.krampe@loginconsultants.de
     Version       : 0.1
     Creation date : 04.03.2022 | v0.1 | Initial script
     Last change   :            |      |  

    NOTICE
    THIS SCRIPT IS PROVIDED “AS IS” WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING 
    ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT. 
    THOMAS KRAMPE, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS OR OMISSIONS CONTAINED HEREIN,
    NOR FOR DIRECT, INCIDENTAL, CONSEQUENTIAL OR ANY OTHER DAMAGES RESULTING FROM THE FURNISHING, 
    PERFORMANCE, OR USE OF THIS SCRIPT, EVEN IF THOMAS KRAMPE HAS BEEN ADVISED OF THE POSSIBILITY 
    OF SUCH DAMAGES IN ADVANCE.
#>

# The hex password saved in a text file is not very secure. 
# Read more about this here https://www.easy365manager.com/pscredential/
# A better way is to ask for credentials with "Get-Credentials" CMDlett, but this is not a good way for automation.
# Choose your own.

$servers = Get-Content "$PSScriptRoot\servers.txt"
$HexPass = Get-Content "$PSScriptRoot\7sS1C5C.txt"
# $Credential = Get-Credential
$Credential = New-Object -TypeName PSCredential -ArgumentList "administrator@licdemo.local", ($HexPass | ConvertTo-SecureString)

# Start the main loop
ForEach ($server in $servers) {

    # Get available updates for target server
    write-host "Starting Windows Updates on $server"
    
    try {
        $up = Invoke-Command -ComputerName $server -ScriptBlock {Start-WUScan -SearchCriteria "Type='Software' AND IsInstalled=0"} -Credential $Credential
    }
    catch {
        Write-Host $_.ScriptStackTrace
    }
    
    if ($up) { 
        # Installing updates on target server
        $upc = $up.count
        write-host "Found $upc updates." 
        
        for ($num = 0 ; $num -le $upc ; $num++){
            write-host "    "$up[$num].Title
        }

        $cs = New-CimSession -ComputerName $server -Credential $Credential
        Install-WUUpdates -Updates $up -CimSession $cs
        
        $rb = Invoke-Command -ComputerName $server -ScriptBlock {Get-WUIsPendingReboot} -Credential $Credential
        
        if ($rb -eq $true) {
            write-host "Reboot required on $server"
            # Restart-Computer -ComputerName $server -Credential $Credential -force
            }
        else { 
            write-host "No reboot required on $server"
            }
        } 
    else {
        write-host "No Updates available for $server"
    } 
}
