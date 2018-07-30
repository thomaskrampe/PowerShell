# sets the certificate as trusted - otherwise publishing will not work automatically


Add-pssnapin citrix*
$PackageID = "d5bd0606-0d55-4cc0-ba7a-a55b29907adc"
$CollectionId = (Get-AMCollection -Current).Id


$LicenseServerAddress = (Get-AMVariable -Id "4972ddd8-5ae0-472d-84f7-f21059b3fcb0" -ComponentId $PackageID -CollectionId $CollectionID).Value | Expand-AMEnvironmentVariables

$licenseServerQueryAddress = "https://" + $LicenseServerAddress + ":8083/"

$cert = Get-LicCertificate  -AdminAddress $licenseServerQueryAddress
Set-ConfigSiteMetadata  -Name "CertificateHash" -Value $cert.certhash