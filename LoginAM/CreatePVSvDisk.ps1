# ===========================================================================================================
#
# Title:              Create Citrix PVS Server vDisk
# Author:             Thomas Krampe - t.krampe@loginconsultants.com
#
# Created:            10.05.2014
#
# Version:            1.0.0
#
# Purpose:            The following script will prepare a Citrix Provisioning Server 7.1 for the
#                     with Automation Machine.
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
# ===========================================================================================================

$ErrorActionPreference = 'SilentlyContinue'

#Prepare Powershel Environment
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Force
Add-PSSnapIn mclipssnapin

# Define Variables
$PVS_Site =  (Get-Item env:pvs_site).Value
$PVS_Store = (Get-Item env:pvs_store).Value
$PVS_vDiskName = (Get-Item env:pvs_vdiskname).Value
$PVS_vDiskSize = (Get-Item env:pvs_vdisksize).Value
$PVS_vDiskBlocksize = (Get-Item env:pvs_vdiskblocksize).Value

#Create vDisk
Mcli-RunWithReturn CreateDisk -p name="$PVS_vDiskName",size="$PVS_vDiskSize",storename="$PVS_Store",SiteName="$PVS_Site",servername="$env:computername",type="1",vhdBlockSize="$PVS_vDiskBlocksize"

