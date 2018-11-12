<#
 .SYNOPSIS
        CleanUpFASCerts.ps1

 .DESCRIPTION
        Lightweight Script for cleanup FAS created, expired certificates.
        This script must run on the certification authority server itself
        
 .PARAMETER Mode
        Delete
        Audit
        
 .EXAMPLE
        Audit
        CleanUpFASCerts.ps1 
        
        Delete
        CleanUpFASCerts.ps1 -delete
        
 .LINK
        https://github.com/thomaskrampe/PowerShell/blob/master/Citrix/FAS/CleanUpFASCerts_v1.0.ps1

 .NOTES
        Author        : Thomas Krampe | thomas.krampe@myctx.net
        Version       : 1.0
        Creation date : 19.09.2018 | v0.1 | Initial script
                      : 20.09.2018 | v1.0 | Release to Github
        Last change   : 12.11.2018 | v1.1 | Remove Typo in var $FileLength

        IMPORTANT NOTICE
        ----------------
        THIS SCRIPT IS PROVIDED "AS IS" WITHOUT WARANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
        ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT.
        THOMAS KRAMPE, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS OR OMISSIONS CONTAINED 
        HEREIN, NOT FOR DIRECT, INCIDENTIAL, CONSEQUENTIAL OR ANY OTHER DAMAGES RESULTING FROM FURNISHING,
        PERFORMANCE, OR USE OF THIS SCRIPT, EVEN IF THOMAS KRAMPE HAS BEEN ADVISED OF THE POSSIBILITY
        OF SUCH DAMAGES IN ADVANCE.

#>
Param (
        [Parameter()]
        [switch]$delete
    )

# -------------------------------------------------------------------------------------------------
# Define global Error handling
# -------------------------------------------------------------------------------------------------
$global:ErrorActionPreference = "Stop"
if($verbose){ $global:VerbosePreference = "Continue" }

# -------------------------------------------------------------------------------------------------
# Log handling
# -------------------------------------------------------------------------------------------------
$LogDir = "C:\_Logs"
$ScriptName = "CleanUpFASCerts"
$CDate = Get-Date -Format dd.MM.yyyy
$LogFileName = $ScriptName + "_" + ($CDate -replace '[\./-]','') + ".log"
$LogFile = Join-path $LogDir $LogFileName

# Create the log directory if it does not exist
if (!(Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType directory | Out-Null }

# Create new log file (overwrite existing one)
New-Item $LogFile -ItemType "file" -force | Out-Null

# -------------------------------------------------------------------------------------------------
# FUNCTIONS (don't change anything here)
# -------------------------------------------------------------------------------------------------
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


} # End function TK_WriteLog

function TK_IsAdmin {
<#
        .SYNOPSIS
            Check if the user running this script has admin permissions
        .DESCRIPTION
            Check if the user running this script has admin permissions
        .EXAMPLE
            TK_IsAdmin
            RETURN $True or $False
    #>
    begin {
    }

    process {
        ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    }
    
    end {
    }
    
} # End function TK_IsAdmin

Function Start-Countdown {   
<#
    .SYNOPSIS
        Provide a graphical countdown if you need to pause a script for a period of time
    .PARAMETER Seconds
        Time, in seconds, that the function will pause
    .PARAMETER Messge
        Message you want displayed while waiting
    .EXAMPLE
        Start-Countdown -Seconds 30 -Message Please wait while Active Directory replicates data...
    .NOTES
        Author:            Martin Pugh
        Twitter:           @thesurlyadm1n
        Spiceworks:        Martin9700
        Blog:              www.thesurlyadmin.com
       
        Changelog:
           2.0             New release uses Write-Progress for graphical display while couting
                           down.
           1.0             Initial Release
    .LINK
        http://community.spiceworks.com/scripts/show/1712-start-countdown
    #>

    Param(
        [Int32]$Seconds = 10,
        [string]$Message = "Pausing for 10 seconds..."
    )
    ForEach ($Count in (1..$Seconds))
    {   Write-Progress -Id 1 -Activity $Message -Status "Waiting for $Seconds seconds, $($Seconds - $Count) left" -PercentComplete (($Count / $Seconds) * 100)
        Start-Sleep -Seconds 1
    }
    Write-Progress -Id 1 -Activity $Message -Status "Completed" -PercentComplete 100 -Completed
}

function TK_GetCaTemplate {

    [CmdletBinding()]
    Param (
        [Parameter()]
        [string]$Filter = "Citrix_SmartcardLogon"
    )

    
    begin {
    }
    
    Process {
        TK_WriteLog "I" "Get template information for template $Filter." $LogFile
        $FilterLength = ("msPKI-Cert-Template-OID=").Length+4
        $AllCATemplates = Invoke-Expression "certutil.exe -catemplates -v | select-string msPKI-Cert-Template-OID"
        $AllCATemplates | foreach {
            $Template = ($_.line).Substring($FilterLength)
            $SplitArray = $Template.split(" ",2)
            $TObject = New-Object PSObject
            Add-Member -InputObject $TObject -Name "name" -MemberType NoteProperty -Value $SplitArray[1].trim()
            Add-Member -InputObject $TObject -Name "oid" -MemberType NoteProperty -Value $SplitArray[0].trim()

            If ($SplitArray[1].trim() -match $Filter) {
                TK_WriteLog "S" "Template $File succesful enumerated." $LogFile
                Write-Output $TObject
            }
        }
    }
    
    end {
    }
} # End function TK_GetCaTemplate

function TK_RemoveExpiredCerts {
    
    
    begin {
    }

    process {
        $DispString = "Issued"
        $Disposition = "20"
        $DateFilter = "notafter"
        $ValidDate = (Get-Date).AddDays(-7).ToString("dd.MM.yyyy")
        $TempFileName = $DispString + ($ValidDate -replace '[\./-]','') + ".txt"
        $TempFilePath = "$LogDir\$DispString"

        [array]$CertTemplateInfo = TK_GetCaTemplate
        $CertTemplate = $CertTemplateInfo.oid
               
        # Creating temporary directory for parsing
        TK_WriteLog "I" "Create temporary directory." $LogFile
        If (-not (Test-Path $TempFilePath)) { New-Item $TempFilePath -ItemType Directory | Out-Null }
        $TempFile = Join-path $TempFilePath $TempFileName
        TK_WriteLog "S" "Temporary directory and parse file created - $TempFile." $LogFile
        TK_WriteLog "I" "Executing: certutil.exe -view -restrict 'certificate template=$CertTemplate,disposition=$Disposition,$DateFilter<=$ValidDate' -out 'Request.RequestID,Request.RequesterName,NotBefore,NotAfter,Request.Disposition' > $TempFile" $LogFile
        Write-Verbose "Executing: certutil.exe -view -restrict 'certificate template=$CertTemplate,disposition=$Disposition,$DateFilter<=$ValidDate' -out 'Request.RequestID,Request.RequesterName,NotBefore,NotAfter,Request.Disposition' > $TempFile"
        Invoke-Expression "certutil.exe -view -restrict 'certificate template=$CertTemplate,disposition=$Disposition,$DateFilter<=$ValidDate' -out 'Request.RequestID,Request.RequesterName,NotBefore,NotAfter,Request.Disposition' > $TempFile"
    
        # Parsing file
        TK_WriteLog "I" "Parsing temporary file." $LogFile
        $RequestsMatching = (Select-String -Path $TempFile -SimpleMatch "Request ID:" | select line)
        
        If ($RequestsMatching -eq $null) {
            TK_WriteLog "I" "Parse file contains no certificates to delete." $LogFile
            Write-verbose "Not certificates to delete in parse file."
            break
            }
        Else {
            TK_WriteLog "I" "Found $($RequestsMatching.length) certificates for removal." $LogFile
            Write-Verbose "Number of certificates to delete: $($RequestsMatching.length)" 
            
            }

        $DelCount = 0;

        $RequestsMatching | foreach {
            $RegIDHex = $_.line -replace "(\s*Request\sID\:\s)(0x[a-f|0-9]+)(.*)",'$2'
            
            Try {

                $RegIDDec = [int]$RegIDHex
            
                If ($delete) {
                    TK_WriteLog "I" "Execute: certutil.exe -deleterow $RegIDHex (Info: $RegIDDec - Decimal)" $LogFile
                    Write-Verbose "certutil.exe -deleterow $RegIDHex (Info: $RegIDDec - Decimal)"
                    & certutil.exe -deleterow $RegIDHex
                    TK_WriteLog "S" "Certificate ID $RegIDHex (Dec: $RegIDDec) succesful deleted." $LogFile
                    }

                $DelCount ++
            }
            catch {
                TK_WriteLog "E" "Error deleting certificates." $LogFile
                Write-verbose "Error deleting certificates."
            }
        }

        If ($delete) {Write-verbose "`nNumber of deleted certificates: $DelCount`n"; TK_WriteLog "I" "Number of deleted certificates: $DelCount" $LogFile }
    }
    
    end {
    }
}

# -------------------------------------------------------------------------------------------------
# MAIN SECTION
# -------------------------------------------------------------------------------------------------
# Disable File Security
$env:SEE_MASK_NOZONECHECKS = 1

Clear-Host

Write-Verbose "Starting script.`n`r" 

# Verify adminstrative permissisions
$AdminPerms = TK_IsAdmin

# Verify installed role
$ADCSFeature = Get-WindowsFeature ADCS-Cert*

# Logging
If ($delete) {TK_WriteLog "I" "START SCRIPT - $ScriptName in DELETE mode." $LogFile}
If (!$delete) {TK_WriteLog "I" "START SCRIPT - $ScriptName in AUDIT mode." $LogFile}
If ($AdminPerms) {TK_WriteLog "I" "Script is running with administrator permissions." $LogFile}
If (!$AdminPerms) {TK_WriteLog "W" "Script is running without administrator permissions" $LogFile}
If (!$ADCSFeature) {TK_WriteLog "E" "Script is not running on a Certification Authority server, because role is not installed." $LogFile; Exit 1}
If ($ADCSFeature) {TK_WriteLog "I" "Script is running on a Certification Authority server, role is installed." $LogFile}

If ($delete) {
    # After that counter there is no way back
    TK_WriteLog "W" "Delete Mode detected - Starting 20 sec. countdown." $LogFile
    Start-Countdown -Seconds 20 -Message "Script run in DELETE MODE!!! You have 20 seconds to break (CTRL-C) this script."
    TK_WriteLog "W" "No CTRL-C after 20sec. - Script will continue." $LogFile
    }

TK_RemoveExpiredCerts

TK_WriteLog "I" "FINISHED - Script finished succesful." $LogFile
Write-Verbose "Script finished succesful.`n`r"
Exit 0
