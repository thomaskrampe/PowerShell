# ===========================================================================================================
#
# Title:              Windows 8 and Server 2012 VDI Optimization Script
# Author:             Thomas Krampe - t.krampe@loginconsultants.com
#
# Created:            18.06.2015
#
# Version:            1.0
#
# Requirements:       Administrative Privileges, Registry backup (Just in case) and of course commonsense ;)
#                     After running that script you should restart the system !!!!
#
#                     THIS SCRIPT IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, 
#                     INCLUDING ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR 
#                     NON-INFRINGEMENT. THOMAS KRAMPE, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS 
#                     OR OMISSIONS CONTAINED HEREIN, NOR FOR DIRECT, INCIDENTAL, CONSEQUENTIAL OR ANY OTHER 
#                     DAMAGES RESULTING FROM THE FURNISHING, PERFORMANCE, OR USE OF THIS SCRIPT, EVEN 
#                     IF THOMAS KRAMPE HAS BEEN ADVISED OF THE POSSIBILITY OF SUCH DAMAGES IN ADVANCE.
#
# License:            Creative Commons CC BY-NC-SA 4.0
#                     http://creativecommons.org/licenses/by-nc-sa/4.0/
# 
# Help:               ItemType	     Description	                      DataType
#                     String	     A string	                          REG_SZ
#                     ExpandString	 A string with environment variables  REG_EXPAND_SZ
#                                    that are resolved when invoked	
#                     Binary	     Binary values	                      REG_BINARY
#                     DWord	         Numeric values	                      REG_DWORD
#                     MultiString	 Text of several lines	              REG_MULTI_SZ
#                     QWord	64-bit   Numeric values	                      REG_QWORD
#
# ===========================================================================================================

# ===================================================
# Variables
# ===================================================

$ErrorActionPreference = 'SilentlyContinue'
$OSName = (Get-WmiObject Win32_OperatingSystem).Caption
$AMEnvName = (Get-Item env:am_env_name).Value

# ===================================================
# Package Settings for Automation Machine
# Get Automation Machine today
# http://www.getautomationmachine.com/en/download
# ===================================================

If($AMEnvName) {
	$FSLogix_VHDLocation = (Get-Item env:FSLogix_VHDLocation).Value
	$FSLogix_SizeInMBs = (Get-Item env:FSLogix_SizeInMBs).Value
	$FSLogix_VolumeType = (Get-Item env:FSLogix_VolumeType).Value
	$FSLogix_VHDXSectorSize = (Get-Item env:FSLogix_VHDXSectorSize).Value
	$FSLogix_IsDynamic = (Get-Item env:FSLogix_IsDynamic).Value
	}

# ===================================================
# Create neccessary registry keys
# ===================================================

New-Item -Path 'HKLM:\SOFTWARE\FSLogix' -Name Profiles
Set-ItemProperty -Name VHDLocation -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Type MultiString -Value $FSLogix_VHDLocation
Set-ItemProperty -Name VolumeType -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Type String -Value $FSLogix_VolumeType
Set-ItemProperty -Name SizeInMBs -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Type DWord -Value $FSLogix_SizeInMBs
Set-ItemProperty -Name VHDXSectorSize -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Type DWord -Value $FSLogix_VHDXSectorSize

If ($FSLogix_IsDynamic -eq $true) {
    Set-ItemProperty -Name IsDynamic -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Type DWord -Value 1
    }
Else {
    Set-ItemProperty -Name IsDynamic -Path 'HKLM:\SOFTWARE\FSLogix\Profiles' -Type DWord -Value 0
    }





