<#
    .SYNOPSIS
        Rename XenServer VM's based on their names in XenCenter and join them to a domain.
    .DESCRIPTION
        Rename XenServer VM's based on their names in XenCenter and join them to a domain.
        Requires XenServer 7.0 SDK's PowerShell Module.
    .PARAMETER XSHost (Mandatory)
        The XenServer where the VM's run
    .PARAMETER XSUser (Mandatory)
        Name Read-Only user on that particular XenServer.
    .PARAMETER XSPassword (Mandatory)
        Password for the XSUser.
    .PARAMETER XenServerHost (Mandatory)
        The XenServer Pool Master to connect to. 
    .PARAMETER UserName (Mandatory)
        Username for XenServer host.
    .PARAMETER Password (Mandatory)
        Password for XenServer host.
    .PARAMETER TargetUser (Mandatory)
        Local Administrator user on the target VM's
    .PARAMETER TargetPassword (Mandatory)
        Password of the local administrator on the target VM's.
    .PARAMETER strUser (Mandatory)
        Domain user with permissions to add machines to the domain.
    .PARAMETER strDomain (Mandatory)
        Domain name to join VM's
    .PARAMETER strtPassword (Mandatory)
        Password of the domain user.
    .PARAMETER DomainController (Mandatory)
        Host name of on Domain Controller to connect to.
    .PARAMETER DHCPPrefix (Mandatory)
        Prefix of the machine name in DHCP server, normally "WIN-".
    .PARAMETER DHCPScope (Mandatory)
        The DHCP scope on the DHCP server (which is a network address).
    .EXAMPLE
        JoinXenServerVMsToDomain.ps1 -XSHost "192.168.0.1" -XSUser "xs-readonly" -XSPassword "Password01!" -TargetUser "Administrator" -TargetPassword "p4ssw0rd" -strUsername "Administrator" -strDomain "domain" -strPassword "p4ssw0rd" -DomainController "testddc01" -DHCPPrefix "WIN-" -DHCPScope "192.168.0.0"

        Description
        -----------
        Rename and join all machines listed in DHCP server with prefix and running on this particular XenServer to a domain.

    .NOTES
        Thomas Krampe - t.krampe@loginconsultants.de
        Version 1.0
#>

<#
Param (
    [Parameter(Mandatory=$true)] [string]$XSHost,
    [Parameter(Mandatory=$true)] [string]$XSUser,
    [Parameter(Mandatory=$true)] [string]$XSPassword,
    [Parameter(Mandatory=$true)] [string]$TargetUser,
    [Parameter(Mandatory=$true)] [string]$TargetPassword,
    [Parameter(Mandatory=$true)] [string]$strUsername,
    [Parameter(Mandatory=$true)] [string]$strDomain,
    [Parameter(Mandatory=$true)] [string]$strPassword,
    [Parameter(Mandatory=$true)] [string]$DomainController,
    [Parameter(Mandatory=$true)] [string]$DHCPPrefix,
    [Parameter(Mandatory=$true)] [string]$DHCPScope
)
#>

# Prepare AM Variables
$XSHost = $env:XenServerHost
$XSUser = $env:XSCredentials.Split(";")[0]
$XSPassword = $env:XSCredentials.Split(";")[1]
$TargetUser = $env:TargetCreds.Split(";")[0]
$TargetPassword = $env:TargetCreds.Split(";")[1]
$strUsername = $env:DomCreds.Split(";")[0]
$strDomain = $env:strDomain
$strPassword = $env:DomCreds.Split(";")[1]
$DomainController = $env:DomainController
$DHCPPrefix = $env:DHCPPrefix
$DHCPScope = $env:DHCPScope

$DomainUserName = $strDomain + "\" + $strUsername
$DomainSecureStringPwd = ConvertTo-SecureString $strPassword -asplaintext -force


# Need this to ensure non-terminating error halt script
$ErrorActionPreference = "Stop"

# Functions
# This function should verify if the computer object collecting from DHCP server is running on the hypervisor
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
        Write-Error "FATAL ERROR - XenServerPSModule not available."
        Exit 99
    }
}

# Create the powershell credential object
$Cred = new-object management.automation.pscredential $DomainUserName,$DomainSecureStringPwd 

# Create the Powershell session
$Session = New-PSSession –Computername $DomainController -Credential $Cred

# Collect MAC addresses from DHCP server
$MacAddresses = Invoke-Command -Session $Session -argumentlist $DHCPScope,$DHCPPrefix -ScriptBlock {Get-DhcpServerv4Lease -ScopeId $args[0] | ? { $_.Hostname -match $args[1] } | Select-Object ClientId,IPAddress,HostName}
Remove-PSSession $Session

# Get current name-label from virtual machines on XenServer
ForEach ($MACAddress in $MacAddresses) {
    $MACReplaced = $MACAddress.ClientID -Replace "-",":"
    $DHCPIPAddress = $MACAddress.IPAddress
    $DHCPFQDNHostName = $MACAddress.HostName
    $VMCheck = get_xen_vm_by_mac $MACReplaced
    
    If ($VMCheck) {

    Write-Host "DEBUG: The VM $VMCheck is running on this Hypervisor with IP address $DHCPIPAddress and hostname $DHCPFQDNHostName."

    # Create local credentials for target access
    $TargetUserDomain = $VMCheck + "\" + $TargetUser
    $TargetSecureStringPwd = ConvertTo-SecureString $TargetPassword -asplaintext -force
    $CredTarget = new-object management.automation.pscredential $TargetUserDomain,$TargetSecureStringPwd 
        
    # Rename the Computer
    $pos = $DHCPFQDNHostName.IndexOf(".")
    $DHCPHostName = $DHCPFQDNHostName.Substring(0, $pos)
    $DHCPDomain = $DHCPFQDNHostName.Substring($pos+1)

    Rename-Computer -ComputerName $DHCPHostName -NewName $VMCheck -LocalCredential $CredTarget -Force -PassThru 
    
    # Join Computer to Domain
    Write-Host "LOG: Adding $VMCheck to domain $DHCPDomain."
   
    # Create the Powershell session
    $JoinSession = New-PSSession –Computername $DHCPHostName -Credential $CredTarget
    
    # Start joining and restart when finish
    Invoke-Command -Session $JoinSession -argumentlist $DHCPDomain,$Cred,$VMCheck -ScriptBlock {Add-Computer -DomainName $args[0] -Credential $args[1] -NewName $args[2] -Restart -Force}
    Remove-PSSession $JoinSession
    
    }
    Else {

        Write-Host "DEBUG: The VM $VMCheck is not running on this particular Hypervisor."
        
    }
    
   
}
