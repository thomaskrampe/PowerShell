Function TK_RemoveWVDHostPool {
    <#
        .SYNOPSIS
            TK_RemoveWVDHostPool
        .DESCRIPTION
            Delete a Windows Virtual Desktop RDS Host Pool in Azure
        .PARAMETER TenantName
            The Name of the WVD Tenant (you can get this with the Get-RdsTenant cmdlet)
        .PARAMETER HostPoolName
            The Name of the host pool (you can get this with the Get-RdsHostPool -TenantName xxx cmdlet)
        .EXAMPLE
            TK_RemoveWVDHostPool -TenantName MyTenant -HostPoolName MyHostPool
            This call remove the Application Group as well as the session host server associated to the Host Pool and finally the hpst pool itself.
        .NOTES
            Author        : Thomas Krampe | t.krampe@loginconsultants.de
            Version       : 1.0
            Creation date : 15.08.2019 | v0.1 | Initial script
            Last change   : 15.08.2019 | v1.0 | Release
           
            IMPORTANT NOTICE
            ----------------
            THIS SCRIPT IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
            ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT.
            LOGIN CONSULTANTS, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS OR OMISSIONS CONTAINED 
            HEREIN, NOT FOR DIRECT, INCIDENTAL, CONSEQUENTIAL OR ANY OTHER DAMAGES RESULTING FROM FURNISHING,
            PERFORMANCE, OR USE OF THIS SCRIPT, EVEN IF LOGIN CONSULTANTS HAS BEEN ADVISED OF THE POSSIBILITY
            OF SUCH DAMAGES IN ADVANCE.
    #>
     
    [CmdletBinding()]
    Param( 
        [Parameter(Mandatory = $true, Position = 0)][String]$TenantName,
        [Parameter(Mandatory = $true, Position = 1)][String]$HostPoolName
    )
  
    begin {
        [string]$FunctionName = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-Verbose "START FUNCTION - $FunctionName"  
        
        [string]$ModuleName = "Microsoft.RDInfra.RDPowerShell"
        
        # If module is already imported there is nothing to do.
        if (Get-Module | Where-Object { $_.Name -eq $ModuleName }) {
            Write-Verbose "Module $ModuleName is already imported."
        }
        else {

            # If module is not imported, but available on disk then import
            if (Get-Module -ListAvailable | Where-Object { $_.Name -eq $ModuleName }) {
                Import-Module $ModuleName -Verbose
            }
            else {

                # If module is not imported, not available on disk, but is in online gallery then install and import
                if (Find-Module -Name $ModuleName | Where-Object { $_.Name -eq $ModuleName }) {
                    Install-Module -Name $ModuleName -Verbose
                    Import-Module $ModuleName -Verbose
                }
                else {

                    # If module is still not available then abort with exit code 1
                    Write-Warning "Module $ModuleName not imported, not local available and not in online gallery, exiting."
                    EXIT 1
                }
            }
        }
        
        # Login to the Windows Virtual Desktop Tenant 
        Add-RdsAccount -DeploymentUrl "https://rdbroker.wvd.microsoft.com"
    }
  
    process {
        # Do some pre-checks
        [string]$TenantCheck = (Get-RdsTenant).TenantName
        
        If ($TenantName -ne $TenantCheck) { 
            Write-Error "Tenant name mismatch. Please verify the tenant name and try again."
            Exit 1
        }
        
        [string]$HostPoolCheck = (Get-RdsHostPool -TenantName $TenantName).HostPoolName

        If ($HostPoolName -ne $HostPoolCheck) {
            Write-Error "Host pool name mismatch. Please verify the host pool name and try again."
            Exit 1
        }
        
        # Remove Application Group associated to the Host Pool 
        Get-RdsAppGroup -TenantName $TenantName -HostPoolName $HostPoolName | Remove-RdsAppGroup 
        # Remove Session Host servers associated to the Host Pool 
        Get-RdsSessionHost -TenantName $TenantName -HostPoolName $HostPoolName | Remove-RdsSessionHost 
        # Remove the Host Pool 
        Get-RdsHostPool -TenantName $TenantName -HostPoolName $HostPoolName | Remove-RdsHostPool 
    }
  
    end {
     
    }
} #EndFunction TK_RemoveWVDHostPool


