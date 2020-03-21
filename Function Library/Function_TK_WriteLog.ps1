function TK_WriteLog {
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
            [Parameter(Mandatory=$true, Position = 0)][ValidateSet("I","S","W","E","-",IgnoreCase = $True)][String]$InformationType,
            [Parameter(Mandatory=$true, Position = 1)][AllowEmptyString()][String]$Text,
            [Parameter(Mandatory=$true, Position = 2)][AllowEmptyString()][String]$LogFile
        )
      
        begin {
        }
      
        process {
         $DateTime = (Get-Date -format dd-MM-yyyy) + " " + (Get-Date -format HH:mm:ss)
      
            if ( $Text -eq "" ) {
                Add-Content $LogFile -value ("") 
            } Else {
             Add-Content $LogFile -value ($DateTime + " " + $InformationType.ToUpper() + " - " + $Text)
            }
        }
      
        end {
        }
     
     
} #EndFunction TK_WriteLog

#region Log handling
# -------------------------------------------------------------------------------------------------
# Log handling
# To use the function above in your own script, make sure that you prepare your log file directory.
# -------------------------------------------------------------------------------------------------
$LogDir = "C:\_Logs"
$ScriptName = "CitrixCloudAutomation"
$DateTime = Get-Date -uformat "%Y-%m-%d_%H-%M"
$LogFileName = "$ScriptName"+"$DateTime.log"
$LogFile = Join-path $LogDir $LogFileName
 
# Create the log directory if it does not exist
if (!(Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType directory | Out-Null }
 
# Create new log file (overwrite existing one)
New-Item $LogFile -ItemType "file" -force | Out-Null
#endregion

