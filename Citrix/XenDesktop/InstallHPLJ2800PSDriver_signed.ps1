####################################################################################################
#
# Script to Install HP LaserJet 2800 Series PS Driver
#
# Author: Thomas Krampe - t.krampe@loginconsultants.de
# Date:   05.11.2018
# Notes:  Citrix KB http://support.citrix.com/article/CTX140208
#         Driver Source https://www.catalog.update.microsoft.com/Search.aspx?q=HP%20LaserJet%202800
#
#####################################################################################################
 
If (-not (Test-Path C:\Driver\HPLJ2800Series -PathType Container)) {
   New-Item C:\Driver\HPLJ2800Series -ItemType directory
   }
 
 
$url = "http://download.windowsupdate.com/msdownload/update/driver/drvs/2011/07/4753_fc148f3df197a4c5cf20bd6a8b337b444037655f.cab"
$output = "C:\Driver\4753_fc148f3df197a4c5cf20bd6a8b337b444037655f.cab"
$start_time = Get-Date
 
Invoke-WebRequest -Uri $url -OutFile $output
Write-Output "Time taken: $((Get-Date).Subtract($start_time).Seconds) second(s)"
 
Set-Location -Path C:\Driver
& expand.exe 4753_fc148f3df197a4c5cf20bd6a8b337b444037655f.cab -F:* C:\Driver\HPLJ2800Series
 
Write-Host "Folder found - Install HP 2800 Series PS Driver"
& pnputil.exe -a "C:\Driver\HPLJ2800Series\prnhp002.inf"
Write-Host "Add Driver to local PrintServer."
Add-PrinterDriver -Name "HP Color LaserJet 2800 Series PS"
Write-Host "Clean-up"
Set-Location -Path $PSScriptRoot
Remove-Item –path  C:\Driver -Recurse
Write-Host "All done!"


# SIG # Begin signature block
# MIINFgYJKoZIhvcNAQcCoIINBzCCDQMCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQU5Xp5VYOyGGzj97bvn/xj5x1A
# a/mgggpYMIIFIDCCBAigAwIBAgIQDE9KA2CiYM0SeQsmH3dOzDANBgkqhkiG9w0B
# AQsFADByMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFz
# c3VyZWQgSUQgQ29kZSBTaWduaW5nIENBMB4XDTE4MDcwNjAwMDAwMFoXDTE5MDcx
# MTEyMDAwMFowXTELMAkGA1UEBhMCREUxHjAcBgNVBAcMFUvDtm5pZ3N0ZWluIGlt
# IFRhdW51czEWMBQGA1UEChMNVGhvbWFzIEtyYW1wZTEWMBQGA1UEAxMNVGhvbWFz
# IEtyYW1wZTCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBAM79VvkGIUUA
# O/Tknko9XrZIQhrltROylsezpMTXD8Sf1iGnLR0GFaU1VBosxLvY8RGima+n7oqB
# kiUIAKRkhQba9JRie0yYg3ITGCx0EX2MbepIslgWfg+nkp+jWEOOkhTGmkSLOCvg
# ZMQZ1djyyoG/D/8bpx+Txt6qHh8PbV1SFNfxuLlRJzFnLc1Wlb9Zvxq3eSHTjw4J
# c+c9X+no/1gZ3yMC6vdzfaGCJXG9uUjiX1kpMd+9DjAjbM69OQAurZ3Apy3HQsbT
# nF0DMQwxphzapMG/2UPxEFxaGtfRNqjk0Bplcny4VJpUJND27FTTnTeeEH9VPMjw
# pq2xcLwlS+UCAwEAAaOCAcUwggHBMB8GA1UdIwQYMBaAFFrEuXsqCqOl6nEDwGD5
# LfZldQ5YMB0GA1UdDgQWBBQ21VScgbanwhgNltA3AwCJ9IJwmTAOBgNVHQ8BAf8E
# BAMCB4AwEwYDVR0lBAwwCgYIKwYBBQUHAwMwdwYDVR0fBHAwbjA1oDOgMYYvaHR0
# cDovL2NybDMuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1jcy1nMS5jcmwwNaAz
# oDGGL2h0dHA6Ly9jcmw0LmRpZ2ljZXJ0LmNvbS9zaGEyLWFzc3VyZWQtY3MtZzEu
# Y3JsMEwGA1UdIARFMEMwNwYJYIZIAYb9bAMBMCowKAYIKwYBBQUHAgEWHGh0dHBz
# Oi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCAYGZ4EMAQQBMIGEBggrBgEFBQcBAQR4
# MHYwJAYIKwYBBQUHMAGGGGh0dHA6Ly9vY3NwLmRpZ2ljZXJ0LmNvbTBOBggrBgEF
# BQcwAoZCaHR0cDovL2NhY2VydHMuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0U0hBMkFz
# c3VyZWRJRENvZGVTaWduaW5nQ0EuY3J0MAwGA1UdEwEB/wQCMAAwDQYJKoZIhvcN
# AQELBQADggEBABJevC7KEZS6eeG9kNvGK2k/J2q4ICT2N8HQ6Y1qQyu9pjVuqmul
# yXLc/jtIsDyrbWoo1gcVtY7d9PzZk7UWtx+Vp7ChhEJQOs6AI9uKgOY/s9eqQFig
# TTU2KGZdFm1SU5hgjKeokML1XNwUW8JuqvG81DnVvqWyLqGX5wgf3zRIUVu1HdUq
# EgA2u9cxAXFQbGzPLF4qHGuXm8IuluKRX000R5kTXg0qFz6jcWAEkaniPpHIBpKB
# J8blBj0R8KjeTJuScHkISLybH9RMPcwn4zi9wgA5pDMyquCk1xrkn0jMcsKvLZSC
# 2lTnfLELqqljcsSu6KhJT33Tp90jPKhZXTUwggUwMIIEGKADAgECAhAECRgbX9W7
# ZnVTQ7VvlVAIMA0GCSqGSIb3DQEBCwUAMGUxCzAJBgNVBAYTAlVTMRUwEwYDVQQK
# EwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xJDAiBgNV
# BAMTG0RpZ2lDZXJ0IEFzc3VyZWQgSUQgUm9vdCBDQTAeFw0xMzEwMjIxMjAwMDBa
# Fw0yODEwMjIxMjAwMDBaMHIxCzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2Vy
# dCBJbmMxGTAXBgNVBAsTEHd3dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lD
# ZXJ0IFNIQTIgQXNzdXJlZCBJRCBDb2RlIFNpZ25pbmcgQ0EwggEiMA0GCSqGSIb3
# DQEBAQUAA4IBDwAwggEKAoIBAQD407Mcfw4Rr2d3B9MLMUkZz9D7RZmxOttE9X/l
# qJ3bMtdx6nadBS63j/qSQ8Cl+YnUNxnXtqrwnIal2CWsDnkoOn7p0WfTxvspJ8fT
# eyOU5JEjlpB3gvmhhCNmElQzUHSxKCa7JGnCwlLyFGeKiUXULaGj6YgsIJWuHEqH
# CN8M9eJNYBi+qsSyrnAxZjNxPqxwoqvOf+l8y5Kh5TsxHM/q8grkV7tKtel05iv+
# bMt+dDk2DZDv5LVOpKnqagqrhPOsZ061xPeM0SAlI+sIZD5SlsHyDxL0xY4PwaLo
# LFH3c7y9hbFig3NBggfkOItqcyDQD2RzPJ6fpjOp/RnfJZPRAgMBAAGjggHNMIIB
# yTASBgNVHRMBAf8ECDAGAQH/AgEAMA4GA1UdDwEB/wQEAwIBhjATBgNVHSUEDDAK
# BggrBgEFBQcDAzB5BggrBgEFBQcBAQRtMGswJAYIKwYBBQUHMAGGGGh0dHA6Ly9v
# Y3NwLmRpZ2ljZXJ0LmNvbTBDBggrBgEFBQcwAoY3aHR0cDovL2NhY2VydHMuZGln
# aWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJlZElEUm9vdENBLmNydDCBgQYDVR0fBHow
# eDA6oDigNoY0aHR0cDovL2NybDQuZGlnaWNlcnQuY29tL0RpZ2lDZXJ0QXNzdXJl
# ZElEUm9vdENBLmNybDA6oDigNoY0aHR0cDovL2NybDMuZGlnaWNlcnQuY29tL0Rp
# Z2lDZXJ0QXNzdXJlZElEUm9vdENBLmNybDBPBgNVHSAESDBGMDgGCmCGSAGG/WwA
# AgQwKjAoBggrBgEFBQcCARYcaHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAK
# BghghkgBhv1sAzAdBgNVHQ4EFgQUWsS5eyoKo6XqcQPAYPkt9mV1DlgwHwYDVR0j
# BBgwFoAUReuir/SSy4IxLVGLp6chnfNtyA8wDQYJKoZIhvcNAQELBQADggEBAD7s
# DVoks/Mi0RXILHwlKXaoHV0cLToaxO8wYdd+C2D9wz0PxK+L/e8q3yBVN7Dh9tGS
# dQ9RtG6ljlriXiSBThCk7j9xjmMOE0ut119EefM2FAaK95xGTlz/kLEbBw6RFfu6
# r7VRwo0kriTGxycqoSkoGjpxKAI8LpGjwCUR4pwUR6F6aGivm6dcIFzZcbEMj7uo
# +MUSaJ/PQMtARKUT8OZkDCUIQjKyNookAv4vcn4c10lFluhZHen6dGRrsutmQ9qz
# sIzV6Q3d9gEgzpkxYz0IGhizgZtPxpMQBvwHgfqL2vmCSfdibqFT+hKUGIUukpHq
# aGxEMrJmoecYpJpkUe8xggIoMIICJAIBATCBhjByMQswCQYDVQQGEwJVUzEVMBMG
# A1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGlnaWNlcnQuY29tMTEw
# LwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgQ29kZSBTaWduaW5nIENB
# AhAMT0oDYKJgzRJ5CyYfd07MMAkGBSsOAwIaBQCgeDAYBgorBgEEAYI3AgEMMQow
# CKACgAChAoAAMBkGCSqGSIb3DQEJAzEMBgorBgEEAYI3AgEEMBwGCisGAQQBgjcC
# AQsxDjAMBgorBgEEAYI3AgEVMCMGCSqGSIb3DQEJBDEWBBRVt6g+mmpa0t77r/Sp
# TXFob6UK6zANBgkqhkiG9w0BAQEFAASCAQAmAfRvDM+1amfyPDdASClCX9bz0Ecc
# VIxmV0o1TEe+P0+SImw5HpkQJtwwW3O+5oPzY3ltIcMQRiREeI49hdTCnpfUlzNV
# 2vKXcImzPTctMr5mgi0H8z6t88Q70KjJTppI8epSL83g4dr1X9EdUj28N4NyVc4a
# DVGLeluJfVZQYcXVq21tczeNE0bvM5wOoOCHco7aN38LuVODb8MAYgippsBF+GF6
# O2elxQJPOqkGwmbTUEPlpI3PpixPF/O0ZDJOxf6YfBcmAX0kBMNRIhfMiLLW9lah
# rpai+Hjlkp9wJz3hhg0w/hzY4FiHKKU6M1RamEgTloTrnTNzFtb7uEv0
# SIG # End signature block
