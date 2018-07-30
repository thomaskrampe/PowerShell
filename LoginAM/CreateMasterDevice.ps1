# ===========================================================================================================
#
# Title:              Create Citrix PVS Master Target Device
# Author:             Thomas Krampe - t.krampe@loginconsultants.com
#
# Created:            10.05.2014
#
# Version:            1.0.0
#
# Purpose:            This script will create a Master Target Device and a initial empty vDisk on a Citrix 
#                     Provisioning Server 7.1. This script is for the use with Automation Machine only.
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
Set-ExecutionPolicy -ExecutionPolicy Bypass -Force
Add-PSSnapIn mclipssnapin

# Define Variables
$PVS_Site =  (Get-Item env:pvs_site).Value
$PVS_Store = (Get-Item env:pvs_store).Value
$PVS_Collection = (Get-Item env:pvs_collection).Value
$PVS_vDiskName = (Get-Item env:pvs_vdiskname).Value
$PVS_vDiskSize = (Get-Item env:pvs_vdisksize).Value
$PVS_vDiskBlocksize = (Get-Item env:pvs_vdiskblocksize).Value
$MD_HostName = (Get-Item env:md_hostname).Value
$MD_MACAddr = (Get-Item env:md_macaddr).Value

#Create vDisk
Mcli-RunWithReturn CreateDisk -p name="$PVS_vDiskName",size="$PVS_vDiskSize",storename="$PVS_Store",SiteName="$PVS_Site",servername="$env:computername",type="1",vhdBlockSize="$PVS_vDiskBlocksize"

#Add new Master Target Device to a collection
Mcli-Add Device -r deviceName="$MD_HostName",collectionName="$PVS_Collection",siteName="$PVS_Site",deviceMac="$MD_MACAddr",bootFrom="2",logLevel="2"

# Set advanced options to the Master Device (eg. Description and Type=1 Test)
Mcli-Set Device -p deviceName="$MD_HostName" -r description="Master Device",type="1"

# Assign the vDisk to the Master Device
$vDiskArray = Mcli-Get DiskLocator -p diskLocatorName="$PVS_vDiskName", siteName="$PVS_Site", storeName="$PVS_Store" -f diskLocatorId
$vDiskUUID = $vDiskArray[4]
$vDiskUUID = $vDiskUUID.substring($vDiskUUID.length - 36, 36)

Mcli-Run AssignDiskLocator -p diskLocatorId="$vDiskUUID",deviceName="$MD_HostName"

