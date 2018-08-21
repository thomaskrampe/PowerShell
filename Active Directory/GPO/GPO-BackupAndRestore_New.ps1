<#
 .SYNOPSIS
        GPO-BackupAndRestore.ps1

 .DESCRIPTION
        Lightweight Script for Ex- and Importing GPO's for e.g. GPO migration

 .PARAMETER Mode
        Export 
        Import

 .EXAMPLE
        GPO-BackupAndRestore.ps1 -Mode Export
        GPO-BackupAndRestore.ps1 -Mode Import

 .LINK
        

 .NOTES
        Author        : Thomas Krampe | t.krampe@loginconsultants.de
        Version       : 1.0
        Creation date : 26.07.2018 | v0.1 | Initial script
                      : 30.07.2018 | v1.0 | Release to GitHub
                      : 02.08.2018 | v1.1 | Provide Domain informations
        Last change   : 13.08.2018 | v1.2 | Customizations

        IMPORTANT NOTICE
        ----------------
        THIS SCRIPT IS PROVIDED "AS IS" WITHOUT WARANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
        ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT.
        THOMAS KRAMPE, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS OR OMISSIONS CONTAINED 
        HEREIN, NOT FOR DIRECT, INCIDENTIAL, CONSEQUENTIAL OR ANY OTHER DAMAGES RESULTING FROM FURNISHING,
        PERFORMANCE, OR USE OF THIS SCRIPT, EVEN IF THOMAS KRAMPE HAS BEEN ADVISED OF THE POSSIBILITY
        OF SUCH DAMAGES IN ADVANCE.

#>
        
# Script parameter        
Param(
    [Parameter(Mandatory=$True)][ValidateSet("Export", "Import")][string]$Mode,
    [string]$Prefix,
    [string]$Suffix,
    [string]$Folder = "C:\_GPO-EXPORT\"
 )
 
# Define global Error handling
$global:ErrorActionPreference = "Stop"
if($verbose){ $global:VerbosePreference = "Continue" }

# Define Variables
$Domain = ([ADSI]"LDAP://RootDSE").ldapServiceName.split(":")[0]
$DomainCtrl = ([ADSI]"LDAP://RootDSE").dnsHostName
$BaseLogDir = "C:\Logs"
$ScriptName = "GPO Handling"
$StartDir = $PSScriptRoot 
$LogDir = (Join-Path $BaseLogDir $ScriptName).Replace(" ","_")
$LogFileName = "$($ScriptName).log"
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
        DS_WriteLog -$InformationType "I" -Text "Copy files to C:\Temp" -LogFile "C:\Logs\MylogFile.log"
        Writes a line containing information to the log file
        .Example
        DS_WriteLog -$InformationType "E" -Text "An error occurred trying to copy files to C:\Temp (error: $($Error[0]))" -LogFile "C:\Logs\MylogFile.log"
        Writes a line containing error information to the log file
        .Example
        DS_WriteLog -$InformationType "-" -Text "" -LogFile "C:\Logs\MylogFile.log"
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
            Add-Content $LogFile -value ("") # Write an empty line
        } Else {
         Add-Content $LogFile -value ($DateTime + " " + $InformationType.ToUpper() + " - " + $Text)
        }
    }
 
    end {
    }


}
 
function TK_ExportGPOs {
    $GPO=Get-GPO -All
    foreach ($Entry in $GPO) {
        $Path=$Folder+$entry.Displayname
        New-Item -ItemType directory -Path $Path
        Backup-GPO -Guid $Entry.id -Path $Path -Domain $Domain -Server $DomainCtrl
    }
}
 
function TK_ImportGPOs {
    $ImportFolder=Get-childItem -Path $Folder -Exclude *.ps1
    foreach ($Entry in $ImportFolder) {
        $Name=$Prefix+$Entry.Name+$Suffix
        $Path=$Folder+$entry.Name
        $ID=Get-ChildItem -Path $Path
        New-GPO -Name $Name -Domain $Domain -Server $DomainCtrl
        Import-GPO -TargetName $Name -Path $Path -BackupId $ID.Name .$Domain -Server $DomainCtrl
    }
}

# -------------------------------------------------------------------------------------------------
# MAIN SECTION
# -------------------------------------------------------------------------------------------------
cls

# Disable File Security
$env:SEE_MASK_NOZONECHECKS = 1
 
TK_WriteLog "I" "START SCRIPT - $ScriptName in $Mode mode." $LogFile
TK_WriteLog "I" "Using Domain Controller $DomainCtrl"
if ($mode -eq "Export") {TK_WriteLog "I" "Exporting GPO Objects to $Folder" $LogFile}
if ($mode -eq "Import") {TK_WriteLog "I" "Importing GPO Objects from $Folder" $LogFile}
TK_WriteLog "-" "" $LogFile

# Import GPO Powershell Module
TK_WriteLog -$InformationType "I" "Try to import GPO PowerShell Module." $LogFile
$ModuleExist = Get-Module -List grouppolicy
If (!$ModuleExist){
    TK_WriteLog "E" "PowerShell Module GroupPolicy doesn't exist." $LogFile
    Write-Host "PowerShell Module GroupPolicy doesn't exist on this machine. Install RSAT Roles or run this script on a Domain Controller (not recommended)." -ForegroundColor Red
    $a = new-object -comobject wscript.shell 
    $intAnswer = $a.popup("Do you want to install the RSAT Tools?", 0,"Install GPMC and RSAT",4) 
    If ($intAnswer -eq 6) { 
        try {
            Install-WindowsFeature GPMC,RSAT-ADDS-Tools
            TK_WriteLog "S" "The windows features were installed successfully!" $LogFile
            } 
            catch {
            TK_WriteLog "E" "An error occurred while installing the windows features (error: $($error[0]))" $LogFile
            Exit 1
            } 
    } else { 
        Write-Host "PowerShell Module GroupPolicy doesn't exist on this machine. Install RSAT Roles manually or run this script on a Domain Controller (not recommended)." -ForegroundColor Red
        Exit 1 
    } 
    
    
    exit 1
}

import-module grouppolicy

 switch ($Mode){
    "Export" {TK_ExportGPOs; break}
    "Import" {TK_ImportGPOs; break}
}
exit 0

