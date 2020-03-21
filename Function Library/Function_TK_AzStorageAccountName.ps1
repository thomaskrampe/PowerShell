


Function TK_AzStorageAccountName {
    <#
        .SYNOPSIS
            TK_AzStorageAccountName
        .DESCRIPTION
            Create a unique storage account name for aAzure
        .PARAMETER StrToHash
            String for the Hash eg. your-company-name
        .PARAMETER CharsToUse
            Character to use 
        .EXAMPLE
            TK_AzStorageAccountName -StrToHash "Login-Consultants" -CharsToUse 12 (max. 64)
        .NOTES
            Author        : Thomas Krampe | t.krampe@loginconsultants.de
            Version       : 1.0
            Creation date : 13.03.2020 | v0.1 | Initial script
            Last change   : 13.03.2020 | v1.0 | Release
           
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
        [Parameter(Mandatory=$true, Position = 0)][String]$StrToHash,
        [Parameter(Mandatory=$true, Position = 1)][Int]$CharsToUse
    )
  
    begin {
        
    }
  
    process {
        $stringAsStream = [System.IO.MemoryStream]::new()
        $writer = [System.IO.StreamWriter]::new($stringAsStream)
        $writer.write($StrToHash)
        $writer.Flush() 
        $stringAsStream.Position = 0
        [string]$strHash = Get-FileHash -InputStream $stringAsStream | Select-Object Hash

        if ([Int]$CharsToUse -gt 64) {
            [Int]$CharsToUse = 64
        }
        
        Write-Host $strHash.Substring(7,[Int]$CharsToUse).ToLower()
    }
  
    end {
     
    }
} #EndFunction TK_AzStorageAccountName

# Example function call
TK_AzStorageAccountName -StrToHash "Login-Consultants" -CharsToUse 12