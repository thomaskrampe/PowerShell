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
Set-Service -Name ssh-agent -StartupType 'Automatic'
Set-Service -Name sshd -StartupType 'Automatic'

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
ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDTtDthK1ChMH22xFIMMH1oPL2/ZMW+Bb1t1IU1rXu+Zy+JLmT/pblVBUR0ZGi7lcCCHaVe7iDiLD07LXWTjsj481cARSh8POsy5BRUp3oBDycUygmHMBswbCWj3pnlvCC7P6c3wVLT2VF5c/3Bt907lwp6jMSq6v27j12cTjZm3FX3I/nGC0hRR9ovdXJRnuWHb7Dd/wgFXk75zydFKFmfZ/K5b7lhX1qHp0k7eh3bGKsRB4LwZG7ShcEBdL6/uZjB9JQlt6E4OJ94s50ihE+kB07yBu3HbrXs8VA6ulAJjTjpgWCWeT/BFcsLEOdGh6ong3kHsaC/B/dbBsvy1KtFzHAJZlge4kj7GWiaoAQT/oyAH7NC5ZL/e4iWFCV/1R5RraVo0bGSQD8imuyNBcfbQM8saPfx0Frlbc21PCM0ut7jN6c+FWkf4MxXMJsnce0R5+JOcdew5WwF4FUCqdO5EVPL5KPs6u4tTIi3cmI2Da7y7QuBSGSFcG6kcTBIMw0= cloud@lic-ans-1
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

