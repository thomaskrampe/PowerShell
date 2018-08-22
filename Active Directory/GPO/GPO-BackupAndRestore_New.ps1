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
    [Parameter(Mandatory=$True)][ValidateSet("Export", "Import", "Audit")][string]$Mode,
    [string]$Prefix,
    [string]$Suffix,
    [string]$Folder = "C:\_GPO-EXPORT\"
 )
 
# Define global Error handling
$global:ErrorActionPreference = "Stop"
if($verbose){ $global:VerbosePreference = "Continue" }

# Define and fill variables
$Domain = ([ADSI]"LDAP://RootDSE").ldapServiceName.split(":")[0]
$DomainCtrl = ([ADSI]"LDAP://RootDSE").dnsHostName

# -------------------------------------------------------------------------------------------------
# Log handling
# -------------------------------------------------------------------------------------------------
$BaseLogDir = "C:\Logs"
$ScriptName = "GPO Handling"
$StartDir = $PSScriptRoot 
$LogDir = (Join-Path $BaseLogDir $ScriptName).Replace(" ","_")
$LogFileName = "$ScriptName.log"
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
            Add-Content $LogFile -value ("") 
        } Else {
         Add-Content $LogFile -value ($DateTime + " " + $InformationType.ToUpper() + " - " + $Text)
        }
    }
 
    end {
    }


}

function TK_IsAdmin {

    begin {
    }

    process {
        ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    }
    
    end {
    }
    
}

function TK_ExportGPOs {

    begin {
    }
    
    process {
    $GPO=Get-GPO -All
    $Server = $DomainCtrl.split(".")[0]
    foreach ($Entry in $GPO) {
        $GPOPath=$Folder+$entry.Displayname
        New-Item -ItemType directory -Path $GPOPath
        TK_WriteLog "S" "Folder $GPOPath succesfully created." $LogFile
        Backup-GPO -Guid $Entry.id -Path $GPOPath -Domain $Domain -Server $Server
        TK_WriteLog "S" "GPO $($Entry.Displayname) with GUID $($Entry.id) succesfully created." $LogFile
        }
    }

    end {
    }
}
 
function TK_ImportGPOs {
    
    begin {
    }

    process {
    $ImportFolder=Get-childItem -Path $Folder -Exclude *.ps1
    $Server = $DomainCtrl.split(".")[0]
    foreach ($Entry in $ImportFolder) {
        $Name=$Prefix+$Entry.Name+$Suffix
        $ImportPath=$Folder+$entry.Name
        $ID=Get-ChildItem -Path $ImportPath
        
        New-GPO -Name $Name -Domain $Domain -Server $Server
        TK_WriteLog "S" "GPO Object $Name in Domain $Domain succesfully created." $LogFile
        Import-GPO -TargetName $Name -Path $ImportPath -BackupId $ID.Name -Domain $Domain -Server $Server
        TK_WriteLog "S" "GPO Import $Name with ID $($id.name) succesfully imported."
        }
    }

    end {
    }
}

function TK_AuditGPOs {
    [CmdletBinding()]
    Param( 
       [String]$AuditFileName = "GPO-Audit.csv"
    )
    begin {
    }

    Process {
       
    if (!(Test-Path $Folder)) { New-Item -Path $Folder -ItemType directory | Out-Null }
    $AuditPath = Join-path $Folder $AuditFileName
    get-gpo -all | select-object Displayname,ID,Description,GPOStatus,CreationTime,ModificationTime,@{Label="ComputerVersion";Expression={$_.computer.dsversion}},@{Label="UserVersion";Expression={$_.user.dsversion}}| export-csv $AuditPath
    TK_WriteLog "I" "Audit report $Auditpath succesfully created." $LogFile
    }

    end {
    }

}

function TK_ImportModule {
    [CmdletBinding()]
    Param( 
        [Parameter(Mandatory=$true, Position = 0)][String]$Module
    )

    begin {
    }

    process {
        $ModuleExist = Get-Module -List $Module
        If (!$ModuleExist){
            TK_WriteLog "E" "PowerShell Module GroupPolicy doesn't exist." $LogFile
            Write-Host "PowerShell Module GroupPolicy doesn't exist on this machine." -ForegroundColor Red
            Write-Host "Please install RSAT Roles or run this script on a Domain Controller (not recommended).\n" -ForegroundColor Red
            # Offer Feature installation
            # $a = new-object -comobject wscript.shell 
            # $intAnswer = $a.popup("Do you want to install the GPMC and RSAT Tools on this machine now?", 0,"Install GPMC and RSAT Features",4)
            # If ($intAnswer -eq 6) { 
            #     try {
            #         
            #         if (!(TK_IsAdmin)){
            #             TK_WriteLog "E" "Missing admin priviliges. Can't install features." $LogFile
            #             throw "Please run this script with admin priviliges."   
            #             Exit 1             
            #             }
            #         else {
            #             Install-WindowsFeature GPMC,RSAT-ADDS-Tools
            #             TK_WriteLog "S" "The windows features were installed successfully!" $LogFile                
            #             }
            #         } 
            #         catch {
            #             TK_WriteLog "E" "An error occurred while installing the windows features (error: $($error[0]))" $LogFile
            #         Exit 1
            #         } 
            # } else { 
            #     TK_WriteLog "I" "Installation of RSAT and GPMC chanceled." $LogFile
            #     Exit 1 
            # }
            Exit 1
        }
        Import-Module $Module    
        TK_WriteLog "S" "GPO Module succesfully imported." $LogFile

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

Write-Host "Starting script in $mode mode.`n`r" 

# Verify adminstrative permissisions
$AdminPerms = TK_IsAdmin

# Logging
TK_WriteLog "I" "START SCRIPT - $ScriptName in $Mode mode." $LogFile
TK_WriteLog "I" "Using Domain Controller $DomainCtrl" $LogFile
if ($mode -eq "export") {TK_WriteLog "I" "Exporting GPO Objects to $Folder" $LogFile}
if ($mode -eq "import") {TK_WriteLog "I" "Importing GPO Objects from $Folder" $LogFile}
if ($mode -eq "audit") {TK_WriteLog "I" "Creating GPO Audit Report in $Folder" $LogFile}
if ($AdminPerms) {TK_WriteLog "I" "Script is running with administrator permissions." $LogFile}
if (!$AdminPerms) {TK_WriteLog "W" "Script is running without administrator permissions" $LogFile}
TK_WriteLog "-" "" $LogFile

# Import PowerShell Module
TK_ImportModule grouppolicy

switch ($Mode){
    "Export" {TK_ExportGPOs; break}
    "Import" {TK_ImportGPOs; break}
    "Audit" {TK_AuditGPOs; break}
}

TK_WriteLog "I" "Script finished succesful." $LogFile
Write-Host "Script finished succesful.`n`r" -ForegroundColor Green
Exit 0

