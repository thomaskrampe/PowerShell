# Sets the License Server certificate as trusted 
# Thomas Krampe <t.krampe@loginconsultants.de>

Add-pssnapin citrix*

# Change IP-address
$LicenseServerAddress = "192.168.1.12"

$licenseServerQueryAddress = "https://" + $LicenseServerAddress + ":8083/"

$cert = Get-LicCertificate  -AdminAddress $licenseServerQueryAddress
Set-ConfigSiteMetadata  -Name "CertificateHash" -Value $cert.certhash