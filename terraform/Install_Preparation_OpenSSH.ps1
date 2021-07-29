Import-Module -Name 'NetSecurity'

# Setup windows update service to manual
$wuauserv = Get-WmiObject Win32_Service -Filter "Name = 'wuauserv'"
$wuauserv_starttype = $wuauserv.StartMode
Set-Service wuauserv -StartupType Manual

# Install OpenSSH Server
Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0

# Install OpenSSH Client
# Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0

# Set service start type
Set-Service -Name ssh-agent -StartupType ‘Automatic’
Set-Service -Name sshd -StartupType ‘Automatic’

# Start services
Start-Service ssh-agent
Start-Service sshd

# Setup windows update service to original
Set-Service wuauserv -StartupType $wuauserv_starttype

# Configure Powershell as default ssh shell
New-ItemProperty -Path "HKLM:\Software\OpenSSH" -Name "DefaultShell" -Value "$Env:SystemRoot\System32\WindowsPowerShell\v1.0\powershell.exe" -PropertyType String -Force

# Restart the service
Restart-Service sshd

# Configure SSH public key
$content = @"
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCjF4UVBeGRntZMv/f9kI/DtYdWbxhfEmPT0D+Ep9iNfBRNdmCqRWHkS3+y7++66OGzAX4VU73BgOu99NiEYxrchgxbZwQu76p5HUEB1nrU+HFdH1cjHVsM7zkyYcyoEHYvhIn2sBVffB++jTvg+X9/fNtFF/mb2WrIR/4selstDWumHTn9k4Xf5z9hNA2c4fGWYD8jocVONdS/+Gj2I9gBhm3MJJ9Fy1zNP5EwhbjKXV8PwQxSXn1Vpvdc+YPfwZr9rmGXevKjX5ZPlhDS3iQU3NwhG61yql1gEVpkKZKSiCjeuh37Bp/VlG5nZzzyHZ+H6xvHimnCpiDOiaFIYsTZ root@ansible.ad.myctx.net
"@ 

# Write public key to file
$content | Set-Content -Path "$Env:ProgramData\ssh\administrators_authorized_keys"

# Set acl on administrators_authorized_keys
$admins = ([System.Security.Principal.SecurityIdentifier]'S-1-5-32-544').Translate( [System.Security.Principal.NTAccount]).Value
$acl = Get-Acl $Env:ProgramData\ssh\administrators_authorized_keys
$acl.SetAccessRuleProtection($true, $false)
$administratorsRule = New-Object system.security.accesscontrol.filesystemaccessrule($admins,"FullControl","Allow")
$systemRule = New-Object system.security.accesscontrol.filesystemaccessrule("SYSTEM","FullControl","Allow")
$acl.SetAccessRule($administratorsRule)
$acl.SetAccessRule($systemRule)
$acl | Set-Acl

# Open Windows Firewall for SSH traffic inbound
New-NetFirewallRule -Name sshd -DisplayName 'OpenSSH Server (sshd)' -Enabled True -Direction Inbound -Protocol TCP -Action Allow -LocalPort 22

