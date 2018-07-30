
<#
 .SYNOPSIS
        GPO-BackupAndRestore.ps1
 .DESCRIPTION
        Easy Script to Ex- and Import GPO's
 .PARAMETER Mode
        Export 
        Import
 .EXAMPLE
        GPO-BackupAndRestore.ps1 -Mode Export
        GPO-BackupAndRestore.ps1 -Mode Import
 .LINK
        https://github.com/thomaskrampe/PowerShell
                 
 .NOTES
        Author        : Thomas Krampe | t.krampe@loginconsultants.de
        Version       : 1.0
        Creation date : 26.07.2018 | v0.1 | Initial script
        Last change   : 30.07.2018 | v1.0 | Release to GitHub
#>

Param(
[Parameter(Mandatory=$True)]
[ValidateSet(„Export“, „Import“)]
[string]$Mode,
 )
 
 # Change the variables to your own need
import-module grouppolicy
$ExportFolder=“c:\_GPO-EXPORT\“
$Importfolder=“c:\_GPO-EXPORT\“
$Prefix=““
$Suffix=““
 
function Export-GPOs {
    $GPO=Get-GPO –All
    foreach ($Entry in $GPO) {
        $Path=$ExportFolder+$entry.Displayname
        New-Item -ItemType directory -Path $Path
        Backup-GPO -Guid $Entry.id -Path $Path
    }
}
 
function Import-GPOs {
    $Folder=Get-childItem -Path $Importfolder -Exclude *.ps1
    foreach ($Entry in $Folder) {
        $Name=$Prefix+$Entry.Name+$Suffix
        $Path=$Importfolder+$entry.Name
        $ID=Get-ChildItem -Path $Path
        New-GPO -Name $Name
        Import-GPO -TargetName $Name -Path $Path -BackupId $ID.Name
    }
}

 switch ($Mode){
    "Export" {Export-GPOs; break}
    "Import" {Import-GPOs; break}
}
exit 0
