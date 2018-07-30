# ===============================================================================================================
#
# Title:              XenServer PSSnapin Register 
# Author:             Thomas Krampe - t.krampe@loginconsultants.com
#
# Version:            1.0
#
# Created:            15.09.2014
#
# Special thanks to : To the Automation Machine Team
#
# Purpose:            The following script will register the XS PSSnapIn DLL and add the
#                     PSSnapIn to PowerShell.
#
# Requirements:       nothing
#
# ===============================================================================================================

$ErrorActionPreference = 'SilentlyContinue'
$Path =(Get-Item 'env:ProgramFiles(x86)').Value + "\Citrix\XenServerPSSnapIn\XenServerPSSnapIn.dll"

If (Test-Path $Path) {
    
    # Register DLL
    & "$env:SystemRoot\Microsoft.NET\Framework64\v2.0.50727\InstallUtil.exe" "$Path"
    
    # Add XenServerPSSnapIn to local PS
    Add-PSSnapIn XenServerPSSnapIn

    $IsInstalled = Get-PSSnapin -registered
    
    If ($IsInstalled){
        Write-Host "XenServerPSSnapIn successful registered."
        }
    Else {
        Write-Host "XenServerPSSnapIn NOT registered. Installation failed."
        }
    }
Else {
    Write-Host "XenServerPSSnapIn not installed!"
    
}


