<#
    .SYNOPSIS
        Get XenServer VM name label from an existing VM by using the MAC-address.
    .DESCRIPTION
        Get XenServer VM name label from an existing VM by using the MAC-address.
        Requires XenServer 6.5 SDK's PowerShell Module.
    .PARAMETER XenServerHost
        The XenServer Pool Master to connect to. 
    .PARAMETER UserName
        Username for XenServer host.
    .PARAMETER Password
        Password for XenServer host.
    .EXAMPLE
        GetXenVMNameLabelbyMAC.ps1 -XenServerHost "1.2.3.4" -UserName "root" -Password "p4ssw0rd" -Windowshost "localhost"

        Description
        -----------
        Get the Name-Label value from a virtual machine on the XenServer host based on the Mac address collected from the Windows host.
        If the WindowsHost parameter is empty, localhost will be used.

    .NOTES
        Thomas Krampe - t.krampe@loginconsultants.de
        Version 1.0
#>

Param (
    [Parameter(Mandatory=$true)] [string]$XenServerHost,
    [Parameter(Mandatory=$true)] [string]$UserName,
    [Parameter(Mandatory=$true)] [string]$Password,
    [Parameter(Mandatory=$false)] [string]$WindowsHost
)

# Functions
Function get_xen_vm_by_mac([STRING]$MACfilter)
{
  $strSession = Connect-XenServer -Server $XenServerHost -UserName $UserName -Password $Password -NoWarnCertificates -SetDefaultSession -PassThru
  $vif = get-xenVIF | ? { $_.MAC -match $MACFilter}
  If ($vif) {$oref = $vif.opaque_ref}
  If ($oref) {$vif_vm = Get-XenVIFProperty -Ref $oref -XenProperty VM}
  If ($vif_vm)
  {
    
    'The VM with MAC: ' + $MACfilter + ' has the Name-Label: ' +$vif_vm.name_label + ' on XenServer ' + $XenServerHost

  }
  Else
  {
    "No Xen VM found which owns the MAC $MACFilter"
  }
  Disconnect-XenServer -Session $strSession
}


# Get adapter information for each network adapter on a given machine.
# Get the machine name or IP
If (!$WindowsHost) {
    $WindowsHost = "localhost"
    }



#pull in namespace and filter by which adapters have an IP address enabled
$colItems = Get-WmiObject -Class "Win32_NetworkAdapterConfiguration" -ComputerName $WindowsHost -Filter "IpEnabled = TRUE"

#iterate and display
ForEach ($objItem in $colItems) {
# write-host
# write-host $objItem.Description
# write-host "MAC Address: " $objItem.MacAddress
# write-host "IP Address: " $objItem.IpAddress
# write-host
# write-host $objItem.MacAddress

}

$result = get_xen_vm_by_mac $objItem.MacAddress
Write-Host "$($MyInvocation.MyCommand): " $result
