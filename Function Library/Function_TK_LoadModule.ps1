Function TK_LoadModule {
    <#
        .SYNOPSIS
            TK_LoadModule
        .DESCRIPTION
            Import a Powershell module from disk, if not present install from powershell gallery.
        .PARAMETER ModuleName
            The name of the PowerShell module
        .EXAMPLE
            TK_LoadModule -ModuleName AzureAD
            Import module if possible. Otherwise try to install from local or, if not available local, from PowerShell Gallery  
        .NOTES
            Author        : Thomas Krampe | t.krampe@loginconsultants.de
            Version       : 1.0
            Creation date : 05.08.2019 | v0.1 | Initial script
            Last change   : 06.08.2019 | v1.0 | Release
           
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
        [Parameter(Mandatory = $true, Position = 0)][String]$ModuleName
    )
  
    begin {
        [string]$FunctionName = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-Verbose "START FUNCTION - $FunctionName"    
    }
  
    process {
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
                    Install-Module -Name $ModuleName -Force -Verbose -Scope CurrentUser
                    Import-Module $ModuleName -Verbose
                }
                else {

                    # If module is still not available then abort with exit code 1
                    Write-Warning "Module $ModuleName not imported, not local available and not in online gallery, exiting."
                    EXIT 1
                }
            }
        }    
    }
  
    end {
        Write-Verbose "END FUNCTION - $FunctionName" 
    }
} #EndFunction TK_LoadModule