<#
 .SYNOPSIS
        GPO-ToolSet.ps1

 .DESCRIPTION
        Lightweight Script for 
        - Ex- and Importing GPO's for e.g. GPO migration
        - Creating version reports as CSV
        - Compare GPO settings

        Logfiles are written to C:\_Logs by default

 .PARAMETER Mode
        Export 
        Import
        Audit
        Compare

 .PARAMETER Prefix
        Only required (not mandatory) if mode is Import
        Import GPO's to a domain and rename them with this prefix

 .PARAMETER Suffix
        Only required (not mandatory) if mode is Import
        Import GPO's to a domain and rename them with this suffix

.PARAMETER Folder
        The target folder for Ex- or Import. Only required if mode is Export or Import 
        Default is C:\_GPO-Toolset

 .PARAMETER GPONames
        Only required if mode is Compare
        Comma separated GPO Names e.g. "GPO1,GPO2"

 .PARAMETER User
        Only required if mode is Compare
        Show differences from the User part of the policies

 .PARAMETER computer
        Only required if mode is Compare
        Show differences from the Computer part of the policies

 .EXAMPLE
        Mode Export / Import
        GPO-ToolSet.ps1 -Mode Export
        GPO-ToolSet.ps1 -Mode Import -Folder "C:\temp" -Prefix "NEW_"-Suffix "_NEW" 

        Mode Audit
        GPO-ToolSet.ps1 -Mode Audit
        GPO-ToolSet.ps1 -Mode Audit -Folder "C:\temp"

        Mode Compare
        GPO-ToolSet.ps1 -Mode Compare -GPONames "GPO1,GPO2" -user
        GPO-ToolSet.ps1 -Mode Compare -GPONames "GPO1,GPO2" -computer

 .LINK
        https://github.com/thomaskrampe/PowerShell/blob/master/Active%20Directory/GPO/GPO-ToolSet.ps1

 .NOTES
        Author        : Thomas Krampe | thomas.krampe@myctx.net
        Version       : 1.3
        Creation date : 26.07.2018 | v0.1 | Initial script
                      : 30.07.2018 | v1.0 | Release to GitHub
                      : 02.08.2018 | v1.1 | Provide Domain informations
                      : 13.08.2018 | v1.2 | Customizations
        Last change   : 23.08.2018 | v1.3 | Add more functionality

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
    [Parameter(Mandatory=$True)][ValidateSet("Export", "Import", "Audit","Compare")][string]$Mode,
    [string]$Prefix,
    [string]$Suffix,
    [string]$Folder = "C:\_GPO-Toolset\",
    [string]$GPONames,
    [switch]$User,
    [switch]$Computer
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
$LogDir = "C:\_Logs"
$ScriptName = "GPO-Toolset"
$LogFileName = "$ScriptName"+"_$mode.log"
$LogFile = Join-path $LogDir $LogFileName

# Create the log directory if it does not exist
if (!(Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType directory | Out-Null }

# Create the output directory if it does not exist
if (!(Test-Path $Folder)) { New-Item -Path $Folder -ItemType directory | Out-Null }

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


}

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
    
}

function TK_ExportGPOs {
<#
        .SYNOPSIS
            Export all GPO objects with there name to a given folder.
        .DESCRIPTION
            Export all GPO objects with there name to a given folder.
        .EXAMPLE
            TK_ExportGPOs
            RETURN nothing
    #>
    begin {
    }
    
    process {
    $GPO=Get-GPO -All
    $Server = $DomainCtrl.split(".")[0]
    foreach ($Entry in $GPO) {
        $GPOPath=$Folder+$entry.Displayname
        if (!(Test-Path $GPOPath)) {New-Item -ItemType directory -Path $GPOPath}
        TK_WriteLog "S" "Folder $GPOPath succesfully created." $LogFile
        Backup-GPO -Guid $Entry.id -Path $GPOPath -Domain $Domain -Server $Server
        TK_WriteLog "S" "GPO $($Entry.Displayname) with GUID $($Entry.id) succesfully created." $LogFile
        }
    }

    end {
    }
}
 
function TK_ImportGPOs {
<#
        .SYNOPSIS
            Import all GPO objects with there name from a given folder.
        .DESCRIPTION
            Import all GPO objects with there name from a given folder.
        .EXAMPLE
            TK_ImportGPOs
            RETURN nothing
    #>    
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
        TK_WriteLog "S" "GPO Import $Name with ID $($id.name) succesfully imported." $LogFile
        }
    }

    end {
    }
}

function TK_AuditGPOs {
<#
        .SYNOPSIS
            Create a simple GPO Report
        .DESCRIPTION
            Create a simple CSV GPO report in a given folder.
        .EXAMPLE
            TK_AuditGPOs
            RETURN nothing
    #>    
    
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
    <#
        .SYNOPSIS
            Importing required PowerShell modules with error handling.
        .DESCRIPTION
            Importing required PowerShell modules with error handling.
        .EXAMPLE
            TK_ImportModule grouppolicy
            RETURN nothing
    #> 
    
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

Function TK_GPOReport {
    <#
        .SYNOPSIS
            Export XML reports for the given GPOs
        .DESCRIPTION
            Export XML reports for the given GPOs
        .EXAMPLE
            TK_GPOReport
    #>
    Param(
        [string[]]$GPONames,
        [string]$Domain,
        [string]$DC,
        [string]$Folder
    )
    
    begin {
    }
    
    process {
        $GPOReport = $null
        ForEach($GPOName in $GPONames)
            {
                $Path = Join-Path -Path $Folder -ChildPath "$GPOName.xml"
                (Get-GPO -Name $GPOName -Domain $Domain -Server $DC).GenerateReportToFile("xml",$Path)
                TK_WriteLog "I" "Create GPO Report for GPO $GPOName in $Path" $LogFile
                [array]$GPOReport + $Path
            }
        Return $GPOReport
    }

    end {
    }

}

Function TK_GPOCompare {
<#
        .SYNOPSIS
            Compare XML reports for the given GPOs
        .DESCRIPTION
           Compare XML reports for the given GPOs
        .EXAMPLE
            TK_GPOReport
            RETURN comparization
    #>
    Param(
        [string[]]$GPOReport
        )
    
    begin {
    }
    
    process {
    
        If ($user) {
            [string]$CompareReportFile = "GPO-Compare_user.csv"
        } else {
            [string]$CompareReportFile = "GPO-Compare_computer.csv"
        }
        
        
        if (!(Test-Path $Folder)) { New-Item -Path $Folder -ItemType directory | Out-Null }
        $ComparePath = Join-path $Folder $CompareReportFile
        TK_WriteLog "I" "Creating comparison report $ComparePath" $LogFile

        [xml]$xml1 = Get-Content -Path $GpoReport[0]
        [xml]$xml2 = Get-Content -Path $GpoReport[1]

        $GPOComputerNodes1 = $xml1.GPO.Computer.ExtensionData.Extension.ChildNodes | Select-Object name, state
        $GPOComputerNodes2 = $xml2.GPO.Computer.ExtensionData.Extension.ChildNodes | Select-Object name, state
        $GPOUserNodes1 = $xml1.GPO.User.ExtensionData.Extension.ChildNodes | Select-Object name, state
        $GPOUserNodes2 = $xml2.GPO.User.ExtensionData.Extension.ChildNodes | Select-Object name, state

        if ($computer){
            Try {
                Write-Host "Comparing Computer GPO's $($GpoReport[0]) with $($GpoReport[1]) `r`n"
                TK_WriteLog "I" "Comparing Computer GPOs $($GpoReport[0]) with $($GpoReport[1])" $LogFile
                Compare-Object -ReferenceObject $GPOComputerNodes1 -DifferenceObject $GPOComputerNodes2 -IncludeEqual -Property name | export-csv $ComparePath
                TK_WriteLog "S" "Computer comparison report created." $LogFile
            }

            Catch [System.Exception] {
                If ($GPOComputerNodes1) {
                    Write-Host "Computer GPO $($GpoReport[0]) settings `r`f"
                    Write-Host $GPOComputerNodes1
                }
                else {
                    Write-Host "Computer GPO $($GpoReport[0]) not set" -ForegroundColor Yellow
                    TK_WriteLog "W" "Computer GPO $($GpoReport[0]) not set" $LogFile
                    Write-Host $GPOComputerNodes2
                }

            If ($GPOComputerNodes2) {
                    Write-Host "Computer GPO $($GpoReport[1]) settings `r`f"
                }
            else {
                    Write-Host "Computer GPO $($GpoReport[1]) not set" -ForegroundColor Yellow
                    TK_WriteLog "W" "Computer GPO $($GpoReport[1]) not set" $LogFile
                }
            }
        }

    if ($user){
        Try {
            Write-Host "Comparing Computer GPO's $($GpoReport[0]) with $($GpoReport[1]) `r`n"
            TK_WriteLog "I" "Comparing User GPOs $($GpoReport[0]) with $($GpoReport[1])" $LogFile
            Compare-Object -ReferenceObject $GPOComputerNodes1 -DifferenceObject $GPOComputerNodes2 -IncludeEqual -Property name | export-csv $ComparePath
            TK_WriteLog "S" "User comparison report created." $LogFile
            }

        Catch [System.Exception] {
            If ($GPOUserNodes1) {
                Write-Host "User GPO $($GpoReport[0]) settings `r`f"
                Write-Host $GPOUserNodes1
                }
            else {
                Write-Host "User GPO $($GpoReport[0]) not set" -ForegroundColor Yellow
                TK_WriteLog "W" "User GPO $($GpoReport[0]) not set" $LogFile
                }

            If ($GPOUserNodes2) {
                Write-Host "User GPO $($GpoReport[1]) settings `r`f"
                Write-Host $GPOUserNodes2
                }
            else {
                Write-Host "User GPO $($GpoReport[1]) not set" -ForegroundColor Yellow
                TK_WriteLog "W" "User GPO $($GpoReport[1]) not set" $LogFile
                }
            }
        }
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
If ($Mode -eq "compare") {
    If (-not ($user -or $computer)) {
        Write-Host "Please specify either -user or -computer when running this script in $mode mode.`n`r" -ForegroundColor Yellow 
        TK_WriteLog "E" "Parameter -user or -computer missing when running $Mode mode." $LogFile
        TK_WriteLog "E" "STOP SCRIPT - Error in $ScriptName in $Mode mode." $LogFile
        exit
    }
}
TK_WriteLog "-" "" $LogFile

# Import PowerShell Module
TK_ImportModule grouppolicy

switch ($Mode){
    "Export" {TK_ExportGPOs; break}
    "Import" {TK_ImportGPOs; break}
    "Audit" {TK_AuditGPOs; break}
    "Compare" {
        $GPOReport = TK_GPOReport -GPONames $GPONames.split(",") -DC $DomainCtrl -Domain $Domain -Folder $Folder
        TK_GPOCompare -GPOReport $GPOReport -User $User -Computer $Computer
        break
    }
}

TK_WriteLog "I" "FINISHED - Script finished succesful." $LogFile
Write-Host "Script finished succesful.`n`r" -ForegroundColor Green
Exit 0

# End of magic
