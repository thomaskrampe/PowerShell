<#
    .SYNOPSIS
        Creates new XenServer VM's from an existing Template.
    .DESCRIPTION
        Creates new XenServer VM's by cloning an existing Template. This script is only for running within
        an Automation Machine environemnt
        Requires XenServer 7.0 SDK's PowerShell Module.
    .PARAMETER VMNames
        Names of new VMs to be created - AM Variables %vmname1%, %vmname2%, %vmname3%, %vmname4%
    .PARAMETER SourceTemplateName
        Name of the Template to be used. - AMVariable %SourceTemplateName%
    .PARAMETER XenServerHost
        The XenServer Pool Master to connect to. AM Variable %XenServerHost%
    .PARAMETER UserName
        Username for XenServer host.- AM Variable %XSCredentials%
    .PARAMETER Password
        Password for XenServer host. - AM Variable %XSCredentials%
    .NOTES
        Thomas Krampe - t.krampe@loginconsultants.de
        Version 1.0
#>


Param(
    [string[]]$VMNames = @($env:vmname1,$env:vmname2,$env:vmname3,$env:vmname4),
    [string]$SourceTemplateName = $env:SourceTemplateName,
    [string]$XenServerHost = $env:XenServerHost,
    [string]$UserName = $env:XSCredentials.Split(";")[0],
    [string]$Password = $env:XSCredentials.Split(";")[1]
)


# Need this to ensure non-terminating error halt script
$ErrorActionPreference = "Stop"

# Import XenServerPSModule
Import-Module XenServerPSModule

if (Get-Module XenServerPSModule | ? {$_.Name -eq "XenServerPSModule"}) {
    
    try {
        # Connect to the XenServer pool master
        Write-Verbose "$($MyInvocation.MyCommand): Connecting to XenServer host: $XenServerHost"
        $session = Connect-XenServer -Server $XenServerHost -UserName $UserName -Password $Password -NoWarnCertificates -SetDefaultSession -PassThru

        if ($session) {
            try {
                $params = @{
                    Async = $true
                    PassThru = $true
                }
                # Get the source VM or Template
                $sourceTemplate = Get-XenVM -Name $SourceTemplateName
                $params.Add("VM",$sourceTemplate)
                
                # Decide if we’re doing a clone or copy (i.e. thin vs. thick provision)
                Write-Verbose "$($MyInvocation.MyCommand): CLONE MODE"
                $params.Add("XenAction","Clone")
                
                # Schedule the creation of the VMs
                $xenTasks = @()
                foreach ($VMName in $VMNames) {
                    Write-Verbose "$($MyInvocation.MyCommand): Scheduling creation of VM '$VMName' from Template '$SourceTemplateName'"
                    $xenTasks += Invoke-XenVM -NewName $VMName @params
                }
                # Wait for the creation to finish
                Write-Verbose "$($MyInvocation.MyCommand): Waiting for clone to finish..."
                foreach ($xenTask in $xenTasks) {
                    $xenTask | Wait-XenTask -ShowProgress
                }
                # If we started with templates, then we need to provision VMs from the copies/clones and wait for the provisioning to finish
                $xenTasks = @()
                foreach ($VMName in $VMNames) {
                Write-Verbose "$($MyInvocation.MyCommand): Provisioning VM '$VMName'"
                $xenTasks += Invoke-XenVM -Name $VMName -XenAction Provision -Async -PassThru
                Write-Verbose "$($MyInvocation.MyCommand): Waiting for provisioning to finish..."
                foreach ($xenTask in $xenTasks) {
                $xenTask | Wait-XenTask -ShowProgress
                    }
                }
                # If we want to start the VMs, then get each VM and schedule a power on
                foreach ($VMName in $VMNames) {
                    $VM = Get-XenVM -Name $VMName
                    Write-Verbose "$($MyInvocation.MyCommand): Scheduling power on of VM '$VMName'"
                    Invoke-XenVM -VM $VM -XenAction Start -Async
                    }
               
            }
            finally {
                # Disconnect from XenServer pool master
                Write-Verbose "$($MyInvocation.MyCommand): Disconnecting from XenServer host"
                Disconnect-XenServer -Session $session
            }
        }
    }
    finally {
        # Finishing
        Write-Verbose "$($MyInvocation.MyCommand): VM creation finished"
        
    }
} else {
    throw "XenServerPSModule not found."
}

