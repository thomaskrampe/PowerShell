<# 
    .SYNOPSIS        
        WVDPreparation.ps1 

    .DESCRIPTION        
        Lightweight Script for prepare a Windows Virtual Desktop environment        
    
    .PARAMETER EPLocation
        Should be matching the namingconvention eg. DEMHM

    .PARAMETER EPClassroom
        Should be a single diget eg. 1 for classroom 1 etc.
    
    .PARAMETER EPImageType
        Should be 2d or 3d (2d machine type = Standard_DS2_v2, 3d machine type = Standard_NV6)
    
    .PARAMETER EPUserCount
        VM's to be created 

    .EXAMPLE
        

    .LINK        
        https://thomas-krampe.com 
    
    .NOTES       
        Author        : Thomas Krampe | thomas.krampe@myctx.net        
        Version       : 0.1            
        Creation date : 05.02.2019 | v0.1 | Initial script         
        Last change   : 07.02.2019 | v1.0 | Add script documentation
                
        IMPORTANT NOTICE 
        ---------------- 
        THIS SCRIPT IS PROVIDED "AS IS" WITHOUT WARANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING        
        ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT.        
        THOMAS KRAMPE, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS OR OMISSIONS CONTAINED         
        HEREIN, NOT FOR DIRECT, INCIDENTIAL, CONSEQUENTIAL OR ANY OTHER DAMAGES RESULTING FROM FURNISHING,        
        PERFORMANCE, OR USE OF THIS SCRIPT, EVEN IF THOMAS KRAMPE HAS BEEN ADVISED OF THE POSSIBILITY        
        OF SUCH DAMAGES IN ADVANCE.

#>

#region Functions
Function TK_WriteLog {
    <#
            .SYNOPSIS
                Write text to log file
            .DESCRIPTION
                Write text to this script's log file
            .PARAMETER InformationType
                This parameter contains the information type prefix. Possible prefixes and information types are:
                    I = Information
                    S = Success
                    W = Warning
                    E = Error
                    - = No status
            .PARAMETER Text
                This parameter contains the text (the line) you want to write to the log file. If text in the parameter is omitted, an empty line is written.
            .PARAMETER LogFile
                This parameter contains the full path, the file name and file extension to the log file (e.g. C:\Logs\MyApps\MylogFile.log)
            .EXAMPLE
                TK_WriteLog -$InformationType "I" -Text "Copy files to C:\Temp" -LogFile "C:\Logs\MylogFile.log"
                Writes a line containing information to the log file
            .EXAMPLE
                TK_WriteLog -$InformationType "E" -Text "An error occurred trying to copy files to C:\Temp (error: $($Error[0]))" -LogFile "C:\Logs\MylogFile.log"
                Writes a line containing error information to the log file
            .EXAMPLE
                TK_WriteLog -$InformationType "-" -Text "" -LogFile "C:\Logs\MylogFile.log"
                Writes an empty line to the log file
            .NOTES
                Author        : Thomas Krampe | t.krampe@loginconsultants.de
                Version       : 1.0
                Creation date : 26.07.2018 | v0.1 | Initial script
                Last change   : 07.09.2018 | v1.0 | Fix some minor typos
          
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
        [Parameter(Mandatory = $true, Position = 0)][ValidateSet("I", "S", "W", "E", "-", IgnoreCase = $True)][String]$InformationType,
        [Parameter(Mandatory = $true, Position = 1)][AllowEmptyString()][String]$Text,
        [Parameter(Mandatory = $true, Position = 2)][AllowEmptyString()][String]$LogFile
    )
      
    begin {
    }
      
    process {
        $DateTime = (Get-Date -format dd-MM-yyyy) + " " + (Get-Date -format HH:mm:ss)
      
        if ( $Text -eq "" ) {
            Add-Content $LogFile -value ("") 
        }
        Else {
            Add-Content $LogFile -value ($DateTime + " " + $InformationType.ToUpper() + " - " + $Text)
        }
    }
      
    end {
    }
     
     
} #EndFunction TK_WriteLog

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
            $Server = $INIValues.informations.hostname
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
        [Parameter(Mandatory = $true, Position = 0)][String]$filePath
    )
     
    begin {
    }
     
    process {
         
        $anonymous = "NoSection"
        $ini = @{ }  
        switch -regex -file $filePath {  
            "^\[(.+)\]$" {
                # Section    
                $section = $matches[1]  
                $ini[$section] = @{ }  
                $CommentCount = 0  
            }  

            "^(;.*)$" {
                # Comment    
                if (!($section)) {  
                    $section = $anonymous  
                    $ini[$section] = @{ }  
                }  
                $value = $matches[1]  
                $CommentCount = $CommentCount + 1  
                $name = "Comment" + $CommentCount  
                $ini[$section][$name] = $value  
            }   

            "(.+?)\s*=\s*(.*)" {
                # Key    
                if (!($section)) {  
                    $section = $anonymous  
                    $ini[$section] = @{ }  
                }  
                $name, $value = $matches[1..2]  
                $ini[$section][$name] = $value  
            }  
        }  
        return $ini  
 
    }
     
    end {
    }
} #EndFunction TK_ReadFromINI

Function TK_LoadModule {
    <#
        .SYNOPSIS
            TK_LoadModule
        .DESCRIPTION
            Import a Powershell module from disk, if not present install from powershell gallery.
        .PARAMETER ModuleName
            The name of the PowerShell module
        .EXAMPLE
            TK_LoadModule -ModuleName AzureAD
            Import module if possible. Otherwise try to install from local or, if not available local, from PowerShell Gallery  
        .NOTES
            Author        : Thomas Krampe | t.krampe@loginconsultants.de
            Version       : 1.0
            Creation date : 05.08.2019 | v0.1 | Initial script
            Last change   : 06.08.2019 | v1.0 | Release
           
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
        [Parameter(Mandatory = $true, Position = 0)][String]$ModuleName
    )
  
    begin {
        [string]$FunctionName = $PSCmdlet.MyInvocation.MyCommand.Name
        TK_WriteLog "I" "START FUNCTION - $FunctionName" $LogFile
           
    }
  
    process {
        # If module is already imported there is nothing to do.
        if (Get-Module | Where-Object { $_.Name -eq $ModuleName }) {
            TK_WriteLog "I" "Module $ModuleName is already imported." $LogFile
        }
        else {

            # If module is not imported, but available on disk then import
            if (Get-Module -ListAvailable | Where-Object { $_.Name -eq $ModuleName }) {
                Import-Module $ModuleName -Verbose
            }
            else {

                # If module is not imported, not available on disk, but is in online gallery then install and import
                if (Find-Module -Name $ModuleName | Where-Object { $_.Name -eq $ModuleName }) {
                    Install-Module -Name $ModuleName -Force -Verbose -Scope CurrentUser
                    Import-Module $ModuleName -Verbose
                }
                else {

                    # If module is still not available then abort with exit code 1
                    TK_WriteLog "E" "Module $ModuleName not imported, not local available and not in online gallery, exiting." $LogFile
                    EXIT 1
                }
            }
        }    
    }
  
    end {
        TK_WriteLog "I" "END FUNCTION - $FunctionName" $LogFile
    }
} #EndFunction TK_LoadModule

#endregion

# Read values from config file
if (!(Test-Path "$PSScriptRoot\WVDPreparation.config.ini")) { Write-Error "Configuration file not exist, exiting." -Category ObjectNotFound; Exit 1 }
$ConfigValues = TK_ReadFromINI "$PSScriptRoot\WVDPreparation.config.ini"

#region Log handling
# -------------------------------------------------------------------------------------------------
# Log handling
# -------------------------------------------------------------------------------------------------
$LogDir = $ConfigValues.BaseConfig.LogDir
$ScriptName = "WVDPreparation"
$DateTime = Get-Date -uformat "%Y-%m-%d_%H-%M"
$LogFileName = "$ScriptName" + "$DateTime.log"
$LogFile = Join-path $LogDir $LogFileName
 
# Create the log directory if it does not exist
if (!(Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType directory | Out-Null }
 
# Create new log file (overwrite existing one)
New-Item $LogFile -ItemType "file" -force | Out-Null
#endregion





