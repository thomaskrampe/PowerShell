# Disable check publisher's certificate revocation (to speed up console start-up)
#================================================================================

set-ItemProperty -path "REGISTRY::\HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\WinTrust\Trust Providers\Software Publishing\" -name State -value 146944