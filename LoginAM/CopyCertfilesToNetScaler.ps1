<#
    .SYNOPSIS
        Copy certificate files to an existing NetScaler.
    .DESCRIPTION
        Copy certificate files to an existing NetScaler.
    .NOTES
        Thomas Krampe - t.krampe@loginconsultants.de
        Version 1.0
#>

$ErrorActionPreference = "Stop"

# Check if Windows Management Framework 5 is installed (https://www.microsoft.com/en-us/download/details.aspx?id=50395)
If ($PSVersionTable.PSVersion.Major -ne 5) {
    Write-Warning -Message "Windows Management Framework 5 not installed. Please install WMF 5 before proceed - https://www.microsoft.com/en-us/download/details.aspx?id=50395"
    exit
    }

# Install SSH Module
Install-Module PoSH-SSH  

# Prepare Variables
$SourcePath = $env:am_workfolder
$NSCertFileName = $env:NSCertFile
$NSCertFileKeyName = $env:NSCertKey
$NSCertFilePath = "$SourcePath\$NSCertFileName"
$NSCertKeyPath = "$SourcePath\$NSCertFileKeyName"
$NSHostIP = $env:NSHostName.Slit("/")[2]
$NSUserName = $env:NSUser.Split(";")[0]
$NSUserPass = $env:NSUser.Split(";")[1] 
$NSSecureStringPwd = ConvertTo-SecureString $NSUserPass -asplaintext -force
$NSCred = new-object management.automation.pscredential $NSUserName,$NSSecureStringPwd

# Copy Certificate files with SCP to the NetScaler
try {
    
    Set-SCPFile -ComputerName $NSHostIP -Credential $NSCred -LocalFile $NSCertFilePath -RemotePath "/nsconfig/ssl/" -AcceptKey $True
    Set-SCPFile -ComputerName $NSHostIP -Credential $NSCred -LocalFile $NSCertKeyPath -RemotePath "/nsconfig/ssl/" -AcceptKey $True
    
    Remove-Item $NSCertFilePath -Force
    Remove-Item $NSCertKeyPath -Force
    }
catch {

    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    Write-Host "File copy failed. $ErrorMessage $FailedItem"

}





