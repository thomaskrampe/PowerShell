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
        
        

Param(
[Parameter(Mandatory=$True)]
[ValidateSet(�Export�, �Import�)]
[string]$Mode
 )
 
 # Change the variables to your own need
import-module grouppolicy
$ExportFolder="c:\_GPO-EXPORT\" # Export GPO Objects to ...
$Importfolder="c:\_GPO-EXPORT\" # Import GPO Objects from ...

# For importing the GPO's to a new domain you can specify either a prefix or a suffix
$Prefix=""
$Suffix=""

# Domaininformation 
$QDomain = "sourcedomain.local" # Source Domain
$QDomainC = "sourcedc."+$QDomain # Source Domain Controller
$TDomain = "targetdomain.local" # Target Domain
$TDOmainC = "targetdc."+$TDomain # Target Domain Controller

 
function Export-GPOs {
    $GPO=Get-GPO �All
    foreach ($Entry in $GPO) {
        $Path=$ExportFolder+$entry.Displayname
        New-Item -ItemType directory -Path $Path
        Backup-GPO -Guid $Entry.id -Path $Path -Domain $QDomain -Server $QDomainC
    }
}
 
function Import-GPOs {
    $Folder=Get-childItem -Path $Importfolder -Exclude *.ps1
    foreach ($Entry in $Folder) {
        $Name=$Prefix+$Entry.Name+$Suffix
        $Path=$Importfolder+$entry.Name
        $ID=Get-ChildItem -Path $Path
        New-GPO -Name $Name  -Domain $TDomain -Server $TDomainC
        Import-GPO -TargetName $Name -Path $Path -BackupId $ID.Name .$TDomain -Server $TDomainC
    }
}

cls

 switch ($Mode){
    "Export" {Export-GPOs; break}
    "Import" {Import-GPOs; break}
}
exit 0

