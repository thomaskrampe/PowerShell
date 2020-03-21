Function TK_CopyVHDToBlob {
    <#
        .SYNOPSIS
            Copy / Download a managed Azure Disk to Azure Storage account
        .DESCRIPTION
            Copy / Download a managed Azure Disk to Azure Storage account
        .PARAMETER SubscriptionID
            Azure Subscription ID eg. 11111111-2222-3333-4444-555555555555
        .PARAMETER ResourceGroupName
            The name of the ResourceGroup where the disk is stored eg. my-resources
        .PARAMETER ManagedDiskName
            The Name of the managed disk eg. test01_OsDisk_1_729ca8fexxxxxx849c2a8d89d21119db
        .PARAMETER DestStorageAccName
            The Name of the destination storage account eg. mystorage
        .PARAMETER DestStorageAccKey
            The access key for that storage account eg. 
        .PARAMETER StorageContainerName
            The Name of the destination container in that storage account eg. myimages
        .PARAMETER VHDFileName
            Name of the VHD file eg. myimage.vhd
        .EXAMPLE
            TK_CopyVHDToBlob -SubscriptionID xxxx -ResourceGroupName "my-resources"" -ManagedDiskName "test01_=OsDisk_1_xxx" -DestStorageAccName "mystorage" -DestStorageAccKey "abcxxxx==" -StorageContainerName "myimages" -VHDFileName "myimage.vhd" 
        .NOTES
            Author        : Thomas Krampe | t.krampe@loginconsultants.de
            Version       : 1.0
            Creation date : 23.08.2019 | v0.1 | Initial script
            Last change   : 23.08.2019 | v1.0 | Release
           
            IMPORTANT NOTICE
            ----------------
            THIS SCRIPT IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
            ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT.
            LOGIN CONSULTANTS, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS OR OMISSIONS CONTAINED 
            HEREIN, NOT FOR DIRECT, INCIDENTAL, CONSEQUENTIAL OR ANY OTHER DAMAGES RESULTING FROM FURNISHING,
            PERFORMANCE, OR USE OF THIS SCRIPT, EVEN IF LOGIN CONSULTANTS HAS BEEN ADVISED OF THE POSSIBILITY
            OF SUCH DAMAGES IN ADVANCE.
    #>
     
    [CmdletBinding()]
    Param( 
        [Parameter(Mandatory = $true, Position = 0)][String]$SubscriptionID,
        [Parameter(Mandatory = $true, Position = 1)][String]$ResourceGroupName,
        [Parameter(Mandatory = $true, Position = 2)][String]$ManagedDiskName,
        [Parameter(Mandatory = $true, Position = 3)][String]$DestStorageAccName,
        [Parameter(Mandatory = $true, Position = 4)][String]$DestStorageAccKey,
        [Parameter(Mandatory = $true, Position = 5)][String]$StorageContainerName,
        [Parameter(Mandatory = $true, Position = 6)][String]$VHDFileName
    )
  
    begin {
        Connect-AzAccount    
    }
  
    process {
        Select-AzSubscription -SubscriptionId $SubscriptionID
        $sas = Grant-AzDiskAccess -ResourceGroupName $ResourceGroupName -DiskName $ManagedDiskName -DurationInSecond 3600 -Access Read

        $destContext = New-AzStorageContext –StorageAccountName $DestStorageAccName -StorageAccountKey $DestStorageAccKey
        $blobcopy = Start-AzStorageBlobCopy -AbsoluteUri $sas.AccessSAS -DestContainer $StorageContainerName -DestContext $destContext -DestBlob $VHDFileName

        while (($blobCopy | Get-AzStorageBlobCopyState).Status -eq "Pending") {
            Start-Sleep -s 30
            $blobCopy | Get-AzStorageBlobCopyState
        } 
    }
  
    end {
     
    }
} #EndFunction TK_CopyVHDToBlob

# Usage Example
$HLSubscriptionID = "11111111-2222-3333-4444-555555555555"
$HLResourceGroupName = "myresources"
$HLManagedDiskName = "test01_OsDisk_1_xxxxxxxxxxxxxxxdb"
$HLDestStorageAccName = "mystorage"
$HLDestStorageAccKey = "xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx=="
$HLStorageContainerName = "myimages"
$HLVHDFileName = "myimage.vhd"

# Function Call
TK_CopyVHDToBlob -SubscriptionID $HLSubscriptionID -ResourceGroupName $HLResourceGroupName -ManagedDiskName $HLManagedDiskName -DestStorageAccName $HLDestStorageAccName -DestStorageAccKey $HLDestStorageAccKey -StorageContainerName $HLStorageContainerName -VHDFileName $HLVHDFileName
