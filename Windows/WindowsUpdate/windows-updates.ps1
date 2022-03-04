# https://www.easy365manager.com/pscredential/
# $Credential = Get-Credential

$servers = Get-Content "C:\temp\server1.txt"
$HexPass = Get-Content "C:\temp\7sS1C5C.txt"
$Credential = New-Object -TypeName PSCredential -ArgumentList "administrator@licdemo.local", ($HexPass | ConvertTo-SecureString)

ForEach ($server in $servers) {

    # Get available updates for target server
    write-host "Starting Windows Updates on $server"
    $up = Invoke-Command -ComputerName $server -ScriptBlock {Start-WUScan -SearchCriteria "Type='Software' AND IsInstalled=0"} -Credential $Credential
    $upc = $up.count
    
    # For ... Next to write update title into log file
    # write-host $up[0].Title
    # write-host $up[1].Title and so on

    if ($up) { 
        # Installing updates on target server
        write-host "Installing $upc updates." 
        $cs = New-CimSession -ComputerName $server -Credential $Credential
        Install-WUUpdates -Updates $up -CimSession $cs
        
        
        
        $rb = Invoke-Command -ComputerName $server -ScriptBlock {Get-WUIsPendingReboot} -Credential $Credential
        
        if ($rb -eq $true) {
            write-host "Reboot required on $server"
            }
        else { 
            write-host "No reboot required on $server"
            }
        } 
    else {
        write-host "No Updates available for $server"
    } 
}