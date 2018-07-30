# -----------------------------------------------------------------
# Script:     FirewallRule-Inbound_SQL.ps1
# Author:     Thomas Krampe
# Date:       01/22/2015
# Keywords:   Security,Firewall, MS-SQL
# -----------------------------------------------------------------

Import-Module NetSecurity
New-NetFirewallRule -DisplayName "Allow TCP 1433 Inbound"-Description "Created by Automation Machine"  -Direction Inbound -RemoteAddress LocalSubnet -Action Allow -EdgeTraversalPolicy Allow -Protocol TCP -LocalPort 1433 