Function TK_CleanupDirectory {
<#
    .SYNOPSIS
        TK_CleanupDirectory
    .DESCRIPTION
        Delete all files and subfolders in one specific directory, but do not delete the main folder itself
    .PARAMETER Directory
        This parameter contains the full path to the directory that needs to cleaned (for example 'C:\Temp')
    .EXAMPLE
        TK_CleanupDirectory -Directory "C:\Temp"
        Deletes all files and subfolders in the directory 'C:\Temp'
    .NOTES
        Author        : Thomas Krampe | t.krampe@loginconsultants.de
        Version       : 1.0
        Creation date : 15.05.2017 | v0.1 | Initial script 
        Last change   : 15.05.2018 | v1.0 | Release
           
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
        if ( Test-Path $Directory ) {
            try {
                Remove-Item "$Directory\*.*" -force -recurse | Out-Null
                Remove-Item "$Directory\*" -force -recurse | Out-Null
                Write-Verbose "Successfully deleted all files and subfolders in the directory $Directory"
            } catch {
                Write-Verbose "An error occurred trying to delete files and subfolders in the directory $Directory (exit code: $($Error[0]))!"
                Exit 1
            }
        } else {
           Write-Verbose "The directory $Directory does not exist." 
        }
    }
 
    end {
        Write-Verbose "END FUNCTION - $FunctionName"
    }
} #EndFunction TK_CleanupDirectory