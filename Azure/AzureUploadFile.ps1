# Upload Files to Azure Storage Container
Function TK_UploadFilesToAzure {
    Param (
        [Parameter(Mandatory)]
        [string]$StorageAccountName,
        [Parameter(Mandatory)]
        [string]$StorageAccountKey,
        [Parameter(Mandatory)]
        [string]$file
    )

    # Login to Azure RM
    Login-AzureRMAccount

    # Prepare Variables
    $StorageContext = New-AzureStorageContext -StorageAccountName $StorageAccountName -StorageAccountKey $StorageAccountKey
    $StorageContainer = Get-AzureStorageContainer -Context $StorageContext

    # Upload File
    Set-AzureStorageBlobContent -File $file -Container $StorageContainer.name -BlobType "Block" -Context $StorageContext -Verbose

    }



