Function TK_CompressDirectory {
    <#
        .SYNOPSIS
            TK_CompressDirectory
        .DESCRIPTION
             Execute the process compress.exe
        .PARAMETER Directory
            his parameter contains the full path to the directory that needs to be compressed (for example C:\temp)
        .EXAMPLE
            TK_CompressDirectory -Directory "C:\temp"
            Compacts the directory 'C:\temp'
        .NOTES
            Author        : Thomas Krampe | t.krampe@loginconsultants.de
            Version       : 1.0
            Creation date : 26.07.2017 | v0.1 | Initial script
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
        Write-Verbose "START FUNCTION - $FunctionName" $LogFile
    }
  
    process {
        Write-Verbose "Compress files in the directory $Directory" $LogFile
        if ( Test-Path $Directory ) {
            try {
                $params = " /C /S /I /Q /F $($Directory)\*"
                start-process "$WinDir\System32\compact.exe" $params -WindowStyle Hidden -Wait
                Write-Verbose "Successfully compressed all files in the directory $Directory"
            } catch {
                Write-Verbose "An error occurred trying to compress the files in the directory $Directory (exit code: $($Error[0]))!"
                Exit 1
            }
        } else {
           Write-verbose "The directory $Directory does not exist. Nothing to do"
        }
    }
  
    end {
        Write-Verbose "END FUNCTION - $FunctionName"
    }
} #EndFunction TK_CompressDirectory