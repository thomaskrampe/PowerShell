Function TK_CreateDirectory {
    <#
        .SYNOPSIS
            TK_CreateDirectory
        .DESCRIPTION
            Create a new directory
        .PARAMETER Directory
            This parameter contains the name of the new directory including the full path (for example C:\Temp\MyNewFolder).
        .EXAMPLE
            TK_CreateDirectory -Directory "C:\Temp\MyNewFolder"
            Creates the new directory "C:\Temp\MyNewFolder"
        .NOTES
            Author        : Thomas Krampe | t.krampe@loginconsultants.de
            Version       : 1.0
            Creation date : 26.07.2018 | v0.1 | Initial script
            Last change   : 26.07.2018 | v1.0 | Release
           
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
        [Parameter(Mandatory=$true, Position = 0)][String]$Directory
    )
 
    begin {
        [string]$FunctionName = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-Verbose "START FUNCTION - $FunctionName"
    }
  
    process {
        Write-verbose "Create directory $Directory"
        if ( Test-Path $Directory ) {
            Write-Verbose "The directory $Directory already exists."
        } else {
            try {
                New-Item -ItemType Directory -Path $Directory -force | Out-Null
                Write-Verbose "Successfully created the directory $Directory."
            } catch {
                Write-Error "An error occurred trying to create the directory $Directory (exit code: $($Error[0]))!"
                Exit 1
            }
        }
    }
 
    end {
        Write-Verbose "END FUNCTION - $FunctionName"
    }
} #EndFunction TK_CreateDirectory