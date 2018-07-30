<#
    .SYNOPSIS
        Get XenServer VM name label from an existing VM by using the MAC-address.
    .DESCRIPTION
        Get XenServer VM name label from an existing VM by using the MAC-address.
        Requires XenServer 6.5 SDK's PowerShell Module.
    .PARAMETER XenServerHost
        The XenServer Pool Master to connect to. 
    .PARAMETER UserName
        Username for XenServer host.
    .PARAMETER Password
        Password for XenServer host.
    .EXAMPLE
        GetXenVMNameLabelbyMAC.ps1 -XenServerHost "1.2.3.4" -UserName "root" -Password "p4ssw0rd" -Windowshost "localhost"

        Description
        -----------
        Get the Name-Label value from a virtual machine on the XenServer host based on the Mac address collected from the Windows host.
        If the WindowsHost parameter is empty, localhost will be used.

    .NOTES
        Thomas Krampe - t.krampe@loginconsultants.de
        Version 1.0
#>

Param (
    [Parameter(Mandatory=$true)] [string]$XenServerHost,
    [Parameter(Mandatory=$true)] [string]$UserName,
    [Parameter(Mandatory=$true)] [string]$Password,
    [Parameter(Mandatory=$false)] [string]$WindowsHost
)

# Functions
Function get_xen_vm_by_mac([STRING]$MACfilter)
{
  $strSession = Connect-XenServer -Server $XenServerHost -UserName $UserName -Password $Password -NoWarnCertificates -SetDefaultSession -PassThru
  $vif = get-xenVIF | ? { $_.MAC -match $MACFilter}
  If ($vif) {$oref = $vif.opaque_ref}
  If ($oref) {$vif_vm = Get-XenVIFProperty -Ref $oref -XenProperty VM}
  If ($vif_vm)
  {
    
    'The VM with MAC: ' + $MACfilter + ' has the Name-Label: ' +$vif_vm.name_label + ' on XenServer ' + $XenServerHost

  }
  Else
  {
    "No Xen VM found which owns the MAC $MACFilter"
  }
  Disconnect-XenServer -Session $strSession
}


# Get adapter information for each network adapter on a given machine.
# Get the machine name or IP
If (!$WindowsHost) {
    $WindowsHost = "localhost"
    }



#pull in namespace and filter by which adapters have an IP address enabled
$colItems = Get-WmiObject -Class "Win32_NetworkAdapterConfiguration" -ComputerName $WindowsHost -Filter "IpEnabled = TRUE"

#iterate and display
ForEach ($objItem in $colItems) {
# write-host
# write-host $objItem.Description
# write-host "MAC Address: " $objItem.MacAddress
# write-host "IP Address: " $objItem.IpAddress
# write-host
# write-host $objItem.MacAddress

}

$result = get_xen_vm_by_mac $objItem.MacAddress
Write-Host "$($MyInvocation.MyCommand): " $result

# SIG # Begin signature block
# MIINJwYJKoZIhvcNAQcCoIINGDCCDRQCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUDPggsZGu/gsHxWUZIOHlLvFt
# 0pGgggppMIIFMDCCBBigAwIBAgIQBAkYG1/Vu2Z1U0O1b5VQCDANBgkqhkiG9w0B
# AQsFADBlMQswCQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYD
# VQQLExB3d3cuZGlnaWNlcnQuY29tMSQwIgYDVQQDExtEaWdpQ2VydCBBc3N1cmVk
# IElEIFJvb3QgQ0EwHhcNMTMxMDIyMTIwMDAwWhcNMjgxMDIyMTIwMDAwWjByMQsw
# CQYDVQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cu
# ZGlnaWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQg
# Q29kZSBTaWduaW5nIENBMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA
# +NOzHH8OEa9ndwfTCzFJGc/Q+0WZsTrbRPV/5aid2zLXcep2nQUut4/6kkPApfmJ
# 1DcZ17aq8JyGpdglrA55KDp+6dFn08b7KSfH03sjlOSRI5aQd4L5oYQjZhJUM1B0
# sSgmuyRpwsJS8hRniolF1C2ho+mILCCVrhxKhwjfDPXiTWAYvqrEsq5wMWYzcT6s
# cKKrzn/pfMuSoeU7MRzP6vIK5Fe7SrXpdOYr/mzLfnQ5Ng2Q7+S1TqSp6moKq4Tz
# rGdOtcT3jNEgJSPrCGQ+UpbB8g8S9MWOD8Gi6CxR93O8vYWxYoNzQYIH5DiLanMg
# 0A9kczyen6Yzqf0Z3yWT0QIDAQABo4IBzTCCAckwEgYDVR0TAQH/BAgwBgEB/wIB
# ADAOBgNVHQ8BAf8EBAMCAYYwEwYDVR0lBAwwCgYIKwYBBQUHAwMweQYIKwYBBQUH
# AQEEbTBrMCQGCCsGAQUFBzABhhhodHRwOi8vb2NzcC5kaWdpY2VydC5jb20wQwYI
# KwYBBQUHMAKGN2h0dHA6Ly9jYWNlcnRzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFz
# c3VyZWRJRFJvb3RDQS5jcnQwgYEGA1UdHwR6MHgwOqA4oDaGNGh0dHA6Ly9jcmw0
# LmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RDQS5jcmwwOqA4oDaG
# NGh0dHA6Ly9jcmwzLmRpZ2ljZXJ0LmNvbS9EaWdpQ2VydEFzc3VyZWRJRFJvb3RD
# QS5jcmwwTwYDVR0gBEgwRjA4BgpghkgBhv1sAAIEMCowKAYIKwYBBQUHAgEWHGh0
# dHBzOi8vd3d3LmRpZ2ljZXJ0LmNvbS9DUFMwCgYIYIZIAYb9bAMwHQYDVR0OBBYE
# FFrEuXsqCqOl6nEDwGD5LfZldQ5YMB8GA1UdIwQYMBaAFEXroq/0ksuCMS1Ri6en
# IZ3zbcgPMA0GCSqGSIb3DQEBCwUAA4IBAQA+7A1aJLPzItEVyCx8JSl2qB1dHC06
# GsTvMGHXfgtg/cM9D8Svi/3vKt8gVTew4fbRknUPUbRupY5a4l4kgU4QpO4/cY5j
# DhNLrddfRHnzNhQGivecRk5c/5CxGwcOkRX7uq+1UcKNJK4kxscnKqEpKBo6cSgC
# PC6Ro8AlEeKcFEehemhor5unXCBc2XGxDI+7qPjFEmifz0DLQESlE/DmZAwlCEIy
# sjaKJAL+L3J+HNdJRZboWR3p+nRka7LrZkPas7CM1ekN3fYBIM6ZMWM9CBoYs4Gb
# T8aTEAb8B4H6i9r5gkn3Ym6hU/oSlBiFLpKR6mhsRDKyZqHnGKSaZFHvMIIFMTCC
# BBmgAwIBAgIQDaVgwuih00YDhSUdHyCfazANBgkqhkiG9w0BAQsFADByMQswCQYD
# VQQGEwJVUzEVMBMGA1UEChMMRGlnaUNlcnQgSW5jMRkwFwYDVQQLExB3d3cuZGln
# aWNlcnQuY29tMTEwLwYDVQQDEyhEaWdpQ2VydCBTSEEyIEFzc3VyZWQgSUQgQ29k
# ZSBTaWduaW5nIENBMB4XDTE2MTAxNDAwMDAwMFoXDTE3MTAxNjEyMDAwMFowbjEL
# MAkGA1UEBhMCREUxDzANBgNVBAgTBkhlc3NlbjEeMBwGA1UEBwwVS8O2bmlnc3Rl
# aW4gaW0gVGF1bnVzMRYwFAYDVQQKEw1UaG9tYXMgS3JhbXBlMRYwFAYDVQQDEw1U
# aG9tYXMgS3JhbXBlMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoBQ5
# jlNk1lMsrOHaRkEktdNCozBe+fU84olX9kqbChACJTaNxCJx8in3R/shHrf3YimQ
# xs+sG0pLw/29QDC8Oovp9iQXQo9AR8ndoCf/SeEF9e4qCrzrRpXWUZP27xOorQvj
# pH+5aMl5T+MxOnJ797Du6ZCATCG6TCgo+FdXxl02EMj5AueP0XlJ9b5/8Hn1PItI
# qbUj2Tea6l/WjGZeIx8Ncw1RWQX/n5L6o8moZZoPsoQz1JSNLG4umxNPS6gn2mMz
# yMtjLLrFGJo/bgdE+e30GC3isBDI7vWC/2Jq8PnaTvoiNj4ap0CXv6Fjzb3ta1IJ
# ys0hvE445Spm6ynGOQIDAQABo4IBxTCCAcEwHwYDVR0jBBgwFoAUWsS5eyoKo6Xq
# cQPAYPkt9mV1DlgwHQYDVR0OBBYEFPeY9LbpDcAHPLMfUUDjuEue6OKQMA4GA1Ud
# DwEB/wQEAwIHgDATBgNVHSUEDDAKBggrBgEFBQcDAzB3BgNVHR8EcDBuMDWgM6Ax
# hi9odHRwOi8vY3JsMy5kaWdpY2VydC5jb20vc2hhMi1hc3N1cmVkLWNzLWcxLmNy
# bDA1oDOgMYYvaHR0cDovL2NybDQuZGlnaWNlcnQuY29tL3NoYTItYXNzdXJlZC1j
# cy1nMS5jcmwwTAYDVR0gBEUwQzA3BglghkgBhv1sAwEwKjAoBggrBgEFBQcCARYc
# aHR0cHM6Ly93d3cuZGlnaWNlcnQuY29tL0NQUzAIBgZngQwBBAEwgYQGCCsGAQUF
# BwEBBHgwdjAkBggrBgEFBQcwAYYYaHR0cDovL29jc3AuZGlnaWNlcnQuY29tME4G
# CCsGAQUFBzAChkJodHRwOi8vY2FjZXJ0cy5kaWdpY2VydC5jb20vRGlnaUNlcnRT
# SEEyQXNzdXJlZElEQ29kZVNpZ25pbmdDQS5jcnQwDAYDVR0TAQH/BAIwADANBgkq
# hkiG9w0BAQsFAAOCAQEACseiw8VRNkAvisJO4BjGECreOPjzmWpHg8Ik2+bGOsHX
# nkJyB/IsM72tN8wz24xyyKn8EHdZcQpxh096yLmTvBtWpPbZJs+jlLfsb1lcmoXO
# oTcQ/tuOH1sWmwr/i96KAKk38UBodZbCdfd1Xm4pdWrmkSZdF5ZJYjAJAYLzIOJA
# REkI3rhkdTOV7TD0cXrl9RzaZ4C3MFnIXHOdtRIn+FpA1xRyWy90dz1frAiEKj7M
# 0mlscsw88s3QkIGEzUJpjVB/Lcr4FMilK0aYt8QXiYI1DLRAXdEJdIBArscCS2p7
# ZVGtMPWCxKUuzvCY5nkG2gicO2BXb7Z36yfi1ScJvzGCAigwggIkAgEBMIGGMHIx
# CzAJBgNVBAYTAlVTMRUwEwYDVQQKEwxEaWdpQ2VydCBJbmMxGTAXBgNVBAsTEHd3
# dy5kaWdpY2VydC5jb20xMTAvBgNVBAMTKERpZ2lDZXJ0IFNIQTIgQXNzdXJlZCBJ
# RCBDb2RlIFNpZ25pbmcgQ0ECEA2lYMLoodNGA4UlHR8gn2swCQYFKw4DAhoFAKB4
# MBgGCisGAQQBgjcCAQwxCjAIoAKAAKECgAAwGQYJKoZIhvcNAQkDMQwGCisGAQQB
# gjcCAQQwHAYKKwYBBAGCNwIBCzEOMAwGCisGAQQBgjcCARUwIwYJKoZIhvcNAQkE
# MRYEFIIBnOz7dRGcm74FpSEk55xyk/gaMA0GCSqGSIb3DQEBAQUABIIBABfa99Gp
# 45kB1xUXOlPQCQ9fKlfDyuSVRxQMT+yg+G01oyxikIuA+qsTBj12quRUT6nzNvFN
# 1Mj7GtXpYe+L576CFiebcx9ntn3+QQ0TYeYpVvZiJaFA+uMa6Qumn4z7kq6Ck8th
# MQuw38OsSkM68bDIrnDNZBB5mkvbL4vf+l1+tcwJNRGB9elKkG42G2XRqDZEuKKg
# U1VJ/K3uKJvjWnD+H8or8XtIJcolcb6YATXQXXafTcWh7wRSafdT9yBvMb4rJ4ku
# c70iqvolMmWzkyXZUXaGvleDHQrhrH+Kl+KtA77oFj7UW1SWYhF3VRPFFiEKbVXU
# 3r8TKRiL9p22ypM=
# SIG # End signature block
