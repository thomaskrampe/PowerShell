Function TK_DeleteDirectory {
    <#
        .SYNOPSIS
            TK_DeleteDirectory
        .DESCRIPTION
            Delete a directory
        .PARAMETER Directory
            This parameter contains the full path to the directory which needs to be deleted (for example C:\Temp\MyFolder).
        .EXAMPLE
            TK_DeleteDirectory -Directory "C:\Temp\MyFolder"
            Deletes the directory "C:\Temp\MyFolder"
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
        Write-Verbose "Delete directory $Directory"
        if ( Test-Path $Directory ) {
            try {
                Remove-Item $Directory -force -recurse | Out-Null
                Write-Verbose "Successfully deleted the directory $Directory"
            } catch {
                Write-Error "An error occurred trying to delete the directory $Directory (exit code: $($Error[0]))!"
                Exit 1
            }
        } else {
           Write-Verbose "The directory $Directory does not exist. Nothing to do"
        }
    }
 
    end {
        Write-Verbose "END FUNCTION - $FunctionName"
    }
} #EndFunction TK_DeleteDirectory