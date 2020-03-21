Function TK_DeleteFile {
    <#
        .SYNOPSIS
            TK_DeleteFile
        .DESCRIPTION
            Delete files
        .PARAMETER File
            This parameter contains the full path to the file that needs to be deleted (for example C:\Temp\MyFile.txt).
        .EXAMPLE
            TK_DeleteFile -File "C:\Temp\*.txt"
            Deletes all files in the directory "C:\Temp" that have the file extension *.txt. *.txt. Files stored within subfolders of 'C:\Temp' are NOT deleted
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
        [Parameter(Mandatory=$true, Position = 0)][String]$File
    )
  
    begin {
        [string]$FunctionName = $PSCmdlet.MyInvocation.MyCommand.Name
        Write-Verbose "START FUNCTION - $FunctionName"
    }
  
    process {
        Write-Verbose "Delete the file '$File'"
        if ( Test-Path $File ) {
            try {
                Remove-Item "$File" | Out-Null
                Write-Verbose "Successfully deleted the file '$File'"
            } catch {
                Write-Error "An error occurred trying to delete the file '$File' (exit code: $($Error[0]))!"
                Exit 1
            }
        } else {
           Write-Verbose "The file '$File' does not exist. Nothing to do"
        }
    }
  
    end {
        Write-Verbose "END FUNCTION - $FunctionName"
    }
} #EndFunction TK_DeleteFile