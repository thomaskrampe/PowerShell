# Install Powershell Core

# Install Chocolatey
Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression

# Install PowerShell core 7.1.3
& C:\ProgramData\chocolatey\choco.exe install powershell-core --version=7.1.3 -y

Start-Sleep -Seconds 120

# Set pwsh as default ssh shell
# Set-ItemProperty -Path "HKLM:\Software\OpenSSH" -Name "DefaultShell" -Value "C:\Program Files\PowerShell\7\pwsh.exe"

# Create an AllUsersCurrentHost profile
if (!(Test-Path -Path $PROFILE.AllUsersAllHosts)) {
    New-Item -ItemType File -Path $PSHOME\profile.ps1 -Force
    Add-Content -Path $PSHOME\Profile.ps1 -Value 'function Prompt { "PS [" + $env:COMPUTERNAME + "] " + (Get-Location) + "> " }'
  }
