

# User credentials for the XenServer
$XSHost = "192.168.1.101"
$XSUser = "xs-readonly"
$XSPassword = "Password01!"

# User credentials for the Target Server
$TargetUser = "Administrator"
$TargetPassword = "Password01!"


# Domain user credentials for the DHCP server
$strUsername = "Administrator"
$strDomain = "myctxlab"
$strUserDomain = $strDomain + "\" + $strUsername
$SecureStringPwd = convertto-securestring "!Man0n2502!" -asplaintext -force
$DomainController = "prod-dc-01"


# Functions
Function get_xen_vm_by_mac([STRING]$MACfilter)
{
    # Import XenServerPSModule
    Import-Module XenServerPSModule

    # Verify that module is available
    If (Get-Module XenServerPSModule | ? {$_.Name -eq "XenServerPSModule"}) {
        $XSSession = Connect-XenServer -Server $XSHost -UserName $XSUser -Password $XSPassword -NoWarnCertificates -SetDefaultSession -PassThru
        $vif = get-xenVIF | ? { $_.MAC -match $MACFilter}
        If ($vif) {$oref = $vif.opaque_ref}
        If ($oref) {$vif_vm = Get-XenVIFProperty -Ref $oref -XenProperty VM}
        If ($vif_vm) {
            Return $vif_vm.name_label
        }
        Else {
            Write-Host = "No Xen VM found which owns the MAC $MACFilter on XenServer $XSHost"
            Return $false
        }
    Disconnect-XenServer -Session $XSSession
    }
    Else {
        Write-Warning "FATAL ERROR - XenServerPSModule not available."
        Exit 99
    }
}

# Create the powershell credential object
$Cred = new-object management.automation.pscredential $strUserDomain,$SecureStringPwd 

# Create the Powershell session
$Session = New-PSSession –Computername $DomainController -Credential $Cred

# Collect MAC addresses from DHCP server
$MacAddresses = Invoke-Command -Session $Session -ScriptBlock {Get-DhcpServerv4Lease -ScopeId "192.168.1.0" | ? { $_.Hostname -match "WIN-" } | Select-Object ClientId,IPAddress,HostName}
Remove-PSSession $Session

# Get current name-label from virtual machines on XenServer
ForEach ($MACAddress in $MacAddresses) {
    $MACReplaced = $MACAddress.ClientID -Replace "-",":"
    $DHCPIPAddress = $MACAddress.IPAddress
    $DHCPHostName = $MACAddress.HostName
    $VMCheck = get_xen_vm_by_mac $MACReplaced
    
    If ($VMCheck) {

    Write-Host "DEBUG: The VM $VMCheck is running on this Hypervisor with IP address $DHCPIPAddress and hostname $DHCPHostName."

    # Create local credentials for target access
    $TargetUserDomain = $VMCheck + "\" + $TargetUser
    $TargetSecureStringPwd = ConvertTo-SecureString $TargetPassword -asplaintext -force
    $CredTarget = new-object management.automation.pscredential $TargetUserDomain,$TargetSecureStringPwd 
        
    # Rename the Computer, join Domain and restart after
    $pos = $DHCPHostName.IndexOf(".")
    $DHCPHostName = $DHCPHostName.Substring(0, $pos)
    write-host "LOG: Renamimg $DHCPHostName - new host name: $VMCheck"
    Rename-Computer -ComputerName $DHCPHostName -NewName $VMCheck -LocalCredential $CredTarget -Force -PassThru 
    
    write-host "LOG: Adding $VMCheck to domain $strDomain"
    # Add-Computer -NewName $VMCheck -DomainName $strDomain -Credential $Cred -OUPath "OU=Deployment,DC=myctx,DC=lab" -Force
    Add-Computer -Credential $Cred -DomainName $strDomain -ComputerName $DHCPHostName -Force -LocalCredential $CredTarget -NewName $VMCheck -Options JoinWithNewName -OUPath '"OU=Deployment,DC=myctx,DC=lab' -PassThru
    Restart-Computer -ComputerName $DHCPHostName -Credential $Cred -Force
    
    }
    Else {

        Write-Host "DEBUG: The VM $VMCheck is not running on this Hypervisor."
        # Falls bereits eine andere WIN-* VM existiert, die nicht auf dem XenServer läuft.
    }
    
   
}
