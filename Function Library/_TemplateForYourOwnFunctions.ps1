Function ShortURL {
    <#
        .SYNOPSIS
            Name of the Function
        .DESCRIPTION
            Short Function description
        .PARAMETER Param1
            Parameter description
        .PARAMETER Param2
            Parameter  ... description
        .EXAMPLE
            Usage example 
        .NOTES
            Author        : Name | E-Mail
            Version       : 1.0
            Creation date : 31.12.2018 | v0.1 | Initial script
            Last change   : 31.12.2018 | v1.0 | Release
           
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
        [Parameter(Mandatory=$true, Position = 0)][String]$longurl
    )
  
    begin {
        
    }
  
    process {
     
        $url ="http://t13k.de/yourls-api.php?signature=9695dd257c&action=shorturl&format=simple&url=$longurl"
        $request = Invoke-WebRequest $url
        $request.Content   
    }
  
    end {
     
    }
} #EndFunction ShortURL

ShortURL "https://www.example.com"