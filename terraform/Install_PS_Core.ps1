# Install Powershell Core

# Install Chocolatey
Invoke-WebRequest https://chocolatey.org/install.ps1 -UseBasicParsing | Invoke-Expression

# Install PowerShell core 7.1.3
& C:\ProgramData\chocolatey\choco.exe install powershell-core --version=7.1.3 -y

# Install nano
& C:\ProgramData\chocolatey\choco.exe install nano -y

Start-Sleep -Seconds 120

# Update PATH variable 
$env:Path = "C:\Program Files\PowerShell\7;C:\ProgramData\chocolatey;" + $env:Path

# Set pwsh-core as default ssh shell
# Set-ItemProperty -Path "HKLM:\Software\OpenSSH" -Name "DefaultShell" -Value "C:\Program Files\PowerShell\7\pwsh.exe"
#########################################################################################################################
# Why I don't do this?
# If we use choco to install additional software we can't upgrade powershell-core from powershell-core 
# in that case it's better to switch to build in PowerShell, upgrade the package and execute pwsh again.
#########################################################################################################################

# Create an AllUsersCurrentHost profile
if (!(Test-Path -Path $PROFILE.AllUsersAllHosts)) {
    New-Item -ItemType File -Path $PSHOME\profile.ps1 -Force
    Add-Content -Path $PSHOME\Profile.ps1 -Value 'function Prompt { "PS [" + $env:COMPUTERNAME + "] " + (Get-Location) + "> " }'
  }
  
# Set service start type
Set-Service -Name ssh-agent -StartupType 'Automatic'
Set-Service -Name sshd -StartupType 'Automatic'

# Restart services
Restart-Service sshd
Restart-Service ssh-agent
