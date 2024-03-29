Function ShortURL {
    <#
        .SYNOPSIS
            ShortURL
        .DESCRIPTION
            Shorten a long URL with my own YOURLS instance and put the result in the clipboard
        .PARAMETER longURL
            The log URL
        .EXAMPLE
           ShortURL "https://www.example.com" 
        .NOTES
            Author        : Name | E-Mail
            Version       : 1.0
            Creation date : 18.04.2021 | v0.1 | Initial script
            Last change   : 18.04.2021 | v1.0 | Release
           
            IMPORTANT NOTICE
            ----------------
            THIS SCRIPT IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
            ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT.
            THOMAS KRAMPE, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS OR OMISSIONS CONTAINED 
            HEREIN, NOT FOR DIRECT, INCIDENTAL, CONSEQUENTIAL OR ANY OTHER DAMAGES RESULTING FROM FURNISHING,
            PERFORMANCE, OR USE OF THIS SCRIPT, EVEN IF THOMAS KRAMPE HAS BEEN ADVISED OF THE POSSIBILITY
            OF SUCH DAMAGES IN ADVANCE.
    #>
     
    [CmdletBinding()]
    Param( 
        [Parameter(Mandatory=$true, Position = 0)][String]$longurl
    )
  
    begin {

        Set-Variable Signature -Option ReadOnly -Value 9695dd257c
        
    }
  
    process {
     
        $url ="http://t13k.de/yourls-api.php?signature=$Signature&action=shorturl&format=simple&url=$longurl"
        $request = Invoke-WebRequest $url
        $shorturl = $request.Content
        Set-Clipboard -Value $shorturl
    }
  
    end {
     
    }
} #EndFunction ShortURL

ShortURL "https://www.test.com"
# SIG # Begin signature block
# MIIIWwYJKoZIhvcNAQcCoIIITDCCCEgCAQExCzAJBgUrDgMCGgUAMGkGCisGAQQB
# gjcCAQSgWzBZMDQGCisGAQQBgjcCAR4wJgIDAQAABBAfzDtgWUsITrck0sYpfvNR
# AgEAAgEAAgEAAgEAAgEAMCEwCQYFKw4DAhoFAAQUH2wFszO6oK8wY3yKN10IG7rd
# uAWgggW1MIIFsTCCBJmgAwIBAgITRQAAAAgrN2P01EvyBwAAAAAACDANBgkqhkiG
# 9w0BAQsFADBYMRMwEQYKCZImiZPyLGQBGRYDbmV0MRUwEwYKCZImiZPyLGQBGRYF
# bXljdHgxEjAQBgoJkiaJk/IsZAEZFgJhZDEWMBQGA1UEAxMNUFJELVBEQy0wMS1D
# QTAeFw0yMTA1MDkyMDQwMDVaFw0yMjA1MDkyMDQwMDVaMGgxEzARBgoJkiaJk/Is
# ZAEZFgNuZXQxFTATBgoJkiaJk/IsZAEZFgVteWN0eDESMBAGCgmSJomT8ixkARkW
# AmFkMQ4wDAYDVQQDEwVVc2VyczEWMBQGA1UEAxMNQWRtaW5pc3RyYXRvcjCCASIw
# DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBANdukhCGSP4sOAK+/jFFL7FkaWBq
# 1SvhMZCGEiH4dW5uVRd3GQQ0qbZjtqDb0UgPrdVpqwN5AwfFf4ZAPWPRwnV0Xzmd
# wC5ldfe67Kun3ap4HdFyEn+enliC1dvHh+V3ni+JrkuQgMNbSZVHlVUm9x3dbFOs
# bU5Uh5QX7XzN/IUSHWaTDhGHV5DuPyC3LDdyx/PqpasQ3l6LyWT03o/iZs9K59Pl
# fajRK706WdAWSJG3PtcXFIISculMTvAwhEh13zcTwkyQhBn6TwX5Rkt0VJTVszuJ
# ljY+x16riv6PX/sP1cwHuaGaqZkfIOkA0dfNQqRZGV3o+RpXaQL02fUeTWcCAwEA
# AaOCAmIwggJeMCUGCSsGAQQBgjcUAgQYHhYAQwBvAGQAZQBTAGkAZwBuAGkAbgBn
# MBMGA1UdJQQMMAoGCCsGAQUFBwMDMA4GA1UdDwEB/wQEAwIHgDAdBgNVHQ4EFgQU
# Axagk/BjWCsjdP1cAW3UXqofzpgwHwYDVR0jBBgwFoAUHOPAVbD46aGl7SbNYy5k
# tBfKB7EwgdIGA1UdHwSByjCBxzCBxKCBwaCBvoaBu2xkYXA6Ly8vQ049UFJELVBE
# Qy0wMS1DQSxDTj1wcmQtcGRjLTAxLENOPUNEUCxDTj1QdWJsaWMlMjBLZXklMjBT
# ZXJ2aWNlcyxDTj1TZXJ2aWNlcyxDTj1Db25maWd1cmF0aW9uLERDPWFkLERDPW15
# Y3R4LERDPW5ldD9jZXJ0aWZpY2F0ZVJldm9jYXRpb25MaXN0P2Jhc2U/b2JqZWN0
# Q2xhc3M9Y1JMRGlzdHJpYnV0aW9uUG9pbnQwgcMGCCsGAQUFBwEBBIG2MIGzMIGw
# BggrBgEFBQcwAoaBo2xkYXA6Ly8vQ049UFJELVBEQy0wMS1DQSxDTj1BSUEsQ049
# UHVibGljJTIwS2V5JTIwU2VydmljZXMsQ049U2VydmljZXMsQ049Q29uZmlndXJh
# dGlvbixEQz1hZCxEQz1teWN0eCxEQz1uZXQ/Y0FDZXJ0aWZpY2F0ZT9iYXNlP29i
# amVjdENsYXNzPWNlcnRpZmljYXRpb25BdXRob3JpdHkwNQYDVR0RBC4wLKAqBgor
# BgEEAYI3FAIDoBwMGkFkbWluaXN0cmF0b3JAYWQubXljdHgubmV0MA0GCSqGSIb3
# DQEBCwUAA4IBAQACX6w0Ajzts5YQUn96ScF/DF9Jr7+8dln+yOAjvisTrJ5RxVne
# AwwkUTtx30qWWdWW6xJRDcrSB7GdxS71ujnXsHQu2bJfKwWAPssrKXGFEKlgUHvh
# gdip+BoyQ1+5hX5Z6xP3Y8CRh+XvtrRJhbseQAVilqU8Hpv4OMw/s/RHDRrTNzgV
# SzjZ9B84faoHlFznvuRyvqrK9ieiHTz5TCwEq9X/gVkDZmMlbroy5gkpMn2/WxVG
# N+j3SqmbwQPFbPLv5mBWhcnTnWPEkA+I7Cuch4vewE6oVc0+uq9wnlVuXJNNYA4n
# /xzFof7mXYiWpoPMt3389dMrFqv6KgZdH2o/MYICEDCCAgwCAQEwbzBYMRMwEQYK
# CZImiZPyLGQBGRYDbmV0MRUwEwYKCZImiZPyLGQBGRYFbXljdHgxEjAQBgoJkiaJ
# k/IsZAEZFgJhZDEWMBQGA1UEAxMNUFJELVBEQy0wMS1DQQITRQAAAAgrN2P01Evy
# BwAAAAAACDAJBgUrDgMCGgUAoHgwGAYKKwYBBAGCNwIBDDEKMAigAoAAoQKAADAZ
# BgkqhkiG9w0BCQMxDAYKKwYBBAGCNwIBBDAcBgorBgEEAYI3AgELMQ4wDAYKKwYB
# BAGCNwIBFTAjBgkqhkiG9w0BCQQxFgQUiAxuWfn5jZjpA/cEnMf8F6wklGQwDQYJ
# KoZIhvcNAQEBBQAEggEAaf4Ahv93g0KkNo38hdBOc1PTkwoKGxZCLfSNp2lzw+Ap
# OPSvOkTW4O9i9nVKKjDbFPP5Q+UyBrMoEhs9cGOaoKxqiFIftkh6WcUUBZAPMKR/
# KXn6mWWiTViVrkoNpGhC8go6RUhroheGVJ/28HU0xMRh1SPLEOwOrPEnX3X91NGW
# 4Xh4aATMW5AGCaWRE+gMW9VC5KazSGUy2rhChg/O9xyEQTrBY+kGZ9mTYyDaBwq3
# wV7lSlUiVSFb2YWElTGIuqNtS/cc+MxHufqexYZY4F/0KiMfQ04tyCPwcJ1nHxVF
# z/OFzJJGSnVup+Yno8ZAAvoYYk4Ibgi0jNQYuE+VJw==
# SIG # End signature block
