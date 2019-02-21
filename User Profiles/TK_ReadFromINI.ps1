Function TK_ReadFromINI {
    <#
        .SYNOPSIS
            TK_ReadFromINI
        .DESCRIPTION
            Get values from INI file 

            Example INI
            -----------
            [owner]
            name=Thomas Krampe
            organization=MyCTX

            [informations]
            hostname=sqlserver
            ipaddress=192.168.1.2    

        .PARAMETER filePath
            Full path to the INI file eg. C:\Temp\server.ini
        .EXAMPLE
            $INIValues = TK_ReadFromINI -filePath "C:\Temp\server.ini"
            
            You can then access values like this:
            $Server = $INIValues.informations.server
            $Organization = $INIValues.owner.organization

        .LINK        
            https://github.com/thomaskrampe/PowerShell/blob/master/User%20Profiles/TK_ReadFromINI.ps1
        .NOTES       
            Author        : Thomas Krampe | thomas.krampe@myctx.net        
            Version       : 1.0            
            Creation date : 21.02.2019 | v0.1 | Initial script         
            Last change   : 21.02.2019 | v1.0 | Add script documentation
                
        IMPORTANT NOTICE 
        ---------------- 
        THIS SCRIPT IS PROVIDED "AS IS" WITHOUT WARANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING        
        ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT.        
        THOMAS KRAMPE, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS OR OMISSIONS CONTAINED         
        HEREIN, NOT FOR DIRECT, INCIDENTIAL, CONSEQUENTIAL OR ANY OTHER DAMAGES RESULTING FROM FURNISHING,        
        PERFORMANCE, OR USE OF THIS SCRIPT, EVEN IF THOMAS KRAMPE HAS BEEN ADVISED OF THE POSSIBILITY        
        OF SUCH DAMAGES IN ADVANCE.

    #>

    [CmdletBinding()]
    
    Param( 
        [Parameter(Mandatory=$true)][String]$filePath
        )
     
    begin {
    }
     
    process {
         
        $anonymous = "NoSection"
        $ini = @{}  
        switch -regex -file $filePath  
            {  
                "^\[(.+)\]$" # Section  
                {  
                    $section = $matches[1]  
                    $ini[$section] = @{}  
                    $CommentCount = 0  
                }  

                "^(;.*)$" # Comment  
                {  
                    if (!($section)) {  
                        $section = $anonymous  
                        $ini[$section] = @{}  
                    }  
                    $value = $matches[1]  
                    $CommentCount = $CommentCount + 1  
                    $name = "Comment" + $CommentCount  
                    $ini[$section][$name] = $value  
                }   

                "(.+?)\s*=\s*(.*)" # Key  
                {  
                    if (!($section)) {  
                        $section = $anonymous  
                        $ini[$section] = @{}  
                    }  
                    $name,$value = $matches[1..2]  
                    $ini[$section][$name] = $value  
                }  
            }  
        return $ini  
 
    }
     
    end {
    }
}

