Function TK_CreateFolderFromCSV {
    <#
        .SYNOPSIS
            TK_CreateFolderFromCSV
        .DESCRIPTION
            Create user folders from CSV file 

            Example CSV
            user,password,realname
            homer,Password!,Homer Simpson
            bart,Password!,Bart Simpson
        .PARAMETER CSVFile
            Full path to the CSV file eg. C:\Temp\userlist.csv
        .PARAMETER TargetPath
            Root path for folder creation eg. C:\Users
        .PARAMETER LogFile
            This parameter contains the full path, the file name and file extension to the log file (e.g. C:\Logs\MyApps\MylogFile.log)
        .EXAMPLE
            TK_CreateFolderFromCSV -CSVFile "C:\Temp\userlist.csv" - TargetPath "C:\Users"
        .LINK        
            https://github.com/thomaskrampe/PowerShell/blob/master/User%20Profiles/TK_CreateUserFolderFromCSV.ps1
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
        [Parameter(Mandatory=$true)][String]$CSVFile,
        [Parameter(Mandatory=$true)][String]$TargetPath
        )
     
    begin {
    }
     
    process {
        $CSVSource = Import-CSV -Path $CSVFile -Delimiter "," 

        foreach ($CSVObject in $CSVSource) {
            $CreateFolder = $TargetPath + "\" + $($CSVObject.User)
            Write-Verbose "Creating folder $CreateFolder."
            New-Item -ItemType directory -Path $CreateFolder | Out-Null
        }
    }
     
    end {
    }
}