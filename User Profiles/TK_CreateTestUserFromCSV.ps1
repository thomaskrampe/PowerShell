Function TK_CreateTestUserFromCSV {
    <#
        .SYNOPSIS
            TK_CreatTestUserFromCSV
        .DESCRIPTION
            Create test user from CSV file 

            Example CSV
            user,password,realname
            homer,Password!,Homer Simpson
            bart,Password!,Bart Simpson

        .PARAMETER CSVFile
            Full path to the CSV file eg. testuser.csv
        .PARAMETER TargetPath
            Root path for folder creation eg. C:\Users
        .PARAMETER LogFile
            This parameter contains the full path, the file name and file extension to the log file (e.g. C:\Logs\MyApps\MylogFile.log)
        .EXAMPLE
            TK_CreateFolderFromCSV -CSVFile "testuser.csv" - TargetPath "C:\Users"
        .LINK        
            https://github.com/thomaskrampe/PowerShell/blob/master/User%20Profiles/TK_CreateUserFolderFromCSV.ps1
        .NOTES       
            Author        : Thomas Krampe | thomas.krampe@myctx.net        
            Version       : 1.0            
            Creation date : 13.03.2019 | v0.1 | Initial script         
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
        [Parameter(Mandatory=$true)][String]$BaseOU,
        [Parameter(Mandatory=$true)][String]$Domain,
        [Parameter(Mandatory=$true)][String]$UserGroup
        )
     
    begin {
                      
        # Check if Module ActiveDirectory is available and loaded
        if (Get-Module -ListAvailable -Name "ActiveDirectory") { 
            Write-Verbose "Module Active Directory exists." 
            if (!(Get-Module "ActiveDirectory")) { 
                Write-Verboset "Module ActiveDirectory is not loaded." 
                Import-Module ActiveDirectory
                }
            }
            Else {
                Write-Verbose "Module ActiveDirectory not available or not installed."
                Exit 1
                }
    }
     
    process {
        # Create Active Directory Group Object
        if (!(Get-ADGroup -Filter {Name -eq $UserGroup} )) { 
            Write-Verbose "Active Directory group object doesn't exist"
            New-ADGroup -Name $UserGroup -SamAccountName $UserGroup -GroupCategory Security -GroupScope Global -DisplayName $UserGroup -Path "CN=Users,$BaseOU" -Description "Script created group"
            }
            Else {
                Write-Verbose "AD Group already exist. Exit script"
                Exit 1
            }
        
        # Verify if CSV file in script directory exist
            $scriptPath = split-path -parent $MyInvocation.MyCommand.Definition
        if (!(Test-Path -Path $scriptPath + "\" + $CSVFile)) {
            Write-Verbose "CSV file not available. Exit script."
            Exit 1
        }    
        
        $CSVSource = Import-CSV -Path $scriptPath + "\" + $CSVFile -Delimiter "," 

        foreach ($CSVObject in $CSVSource) {
            $UPName = $($CSVObject.user) + "@" + $Domain
            
            Write-Verbose "Creating user $($CSVObject.realname)."
            New-ADUser -Name $($CSVObject.user) -SamAccountName $($CSVObject.user) -UserPrincipalName $UPName -PasswordNeverExpires $true -OtherAttributes @{'mail'="chewdavid@fabrikam.com"}
            
            New-Item -ItemType directory -Path $CreateFolder | Out-Null
            if ( $(Try { Test-Path $CreateFolder.trim() } Catch { $false }) ) {
                Write-Verbose "Folder $CreateFolder created successful."
            }
            Else {
                Write-Error "Creating folder $CreateFolder failed." -targetobject $_ -Category WriteError -RecommendedAction "Maybe missing permissions." 
            }
        }
    }
     
    end {
    }
}