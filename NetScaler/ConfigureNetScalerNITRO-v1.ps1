<#
    .SYNOPSIS
        Configure an existing NetScaler for XenDesktop.
    .DESCRIPTION
        Configure an existing NetScaler for XenDesktop.
    .PARAMETER NShostname 
        The URL of the NetScaler (NSIP) with http:// or https:// prefix.
    .PARAMETER NSIP 
        The IPL of the NetScaler Management interface (NSIP).
    .PARAMETER NSusername 
        Name of the root user (eg. nsroot).
    .PARAMETER NSpassword 
        Password for the root user (eg. nsroot).
    .PARAMETER NSTimeZone 
        The Time zone for this NetScaler (e.g. GMT+01:00-CET-Europe/Berlin)
    .PARAMETER SNIP 
        The Subnet IP-address to be used (SNIP). 
    .PARAMETER SNIPMask 
        Subnetmask for the SNIP.
    .PARAMETER DNSServer 
        The DNS Server for this environment.
    .PARAMETER DNSSuffix 
        The DNS Suffix for this environment (e.g. mycorp.local).
    .PARAMETER NTPServer 
        The NTP Server for this environment (e.g. pool.ntp.org or IP-Address).
    .PARAMETER SFVIP 
        The virtual IP-Address for Storefront Loadbalancing
    .PARAMETER SFServer 
        Hostname of the Storefront Server
    .PARAMETER SFServerIP
        IP-Address of the Storefront Server
    .PARAMETER DCServerIP 
        IP-Address of the Domain Controller
    .PARAMETER DCBaseDN  
        Base DN for the Active Directory (e.g. dc=company,dc=tld)
    .PARAMETER DCBindDNName 
        Read Account for the AD (e.g. user@domain.tld)
    .PARAMETER DCBindDNPass 
        Password for the AD user (Attention - readable in script)
    .PARAMETER DDCHostname 
        Hostname of the Delivery Controller
    .PARAMETER DDCIP 
        IP-Address of the Delivery Controller
    .PARAMETER GatewayFQDN 
        External FQDN for the NSG
    .PARAMETER GWVIP 
        Vitual IP-Address for the NSG vServer
    .PARAMETER GatewaySTA 
        STA Server (e.g. http://staserver normally the DDC)
    .PARAMETER vSRVCertName 
        Name of the external certificate pair
    .PARAMETER vSRVCertFile 
        File name of the external certificate
    .PARAMETER vSRVCertKey 
        File name of the external private key
    .PARAMETER vSRVCertKeyPass 
        Password of the external private key
    .PARAMETER vSRVCertNameInt 
        Name of the internal certificate pair
    .PARAMETER vSRVCertFileInt 
        File name of the internal certificate
    .PARAMETER vSRVCertKeyInt 
        File name of the internal private key
    .PARAMETER vSRVCertKeyPassInt 
        Password of the internal private key
    .NOTES
        Thomas Krampe - t.krampe@loginconsultants.de
        Version 1.0
#>

Param (
    [string]$NShostname = "http://192.168.0.100",
    [string]$NSIP = "192.168.0.100",
    [string]$NSusername = "nsroot",
    [string]$NSpassword = "nsroot",
    [string]$NSTimeZone = "GMT+01:00-CET-Europe/Berlin",
    [string]$SNIP = "192.168.0.101",
    [string]$SNIPMask = "255.255.255.0",
    [string]$DNSServer = "192.168.0.2",
    [string]$DNSSuffix = "company.tld",
    [string]$NTPServer = "192.168.0.2",
    [string]$SFVIP = "192.168.0.103",
    [string]$SFServer = "sf-01",
    [string]$SFServerIP = "192.168.0.109",
    [string]$DCServerIP = "192.168.0.2",
    [string]$DCBaseDN = "dc=company,dc=tld",
    [string]$DCBindDNName = "readonly@company.tld",
    [string]$DCBindDNPass = "Password01!",
    [string]$DDCHostname = "ddc-01",
    [string]$DDCIP = "192.168.0.107",
    [string]$GatewayFQDN = "extern.company.tld",
    [string]$GWVIP = "192.168.1.142",
    [string]$GatewaySTA = "http://192.168.0.107",
    [string]$vSRVCertName = "wildcard_company_tld",
    [string]$vSRVCertFile = "wildcard_company_tld.crt",
    [string]$vSRVCertKey = "wildcard_company_tld.pem",
    [string]$vSRVCertKeyPass = "Password01",
    [string]$vSRVCertNameInt ="",
    [string]$vSRVCertFileInt = "",
    [string]$vSRVCertKeyInt = "",
    [string]$vSRVCertKeyPassInt = ""
)

$ErrorActionPreference = "Stop"

#########################################################################################################
# START - Function Block 
#########################################################################################################

# Ignore Cert Errors because of self-signed certifcates
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = { $true }


function NSLogin {
<#
    .SYNOPSIS
        Login to NetScaler and save session information to a variable
#>
$body = ConvertTo-JSON @{
    "login"=@{
        "username"="$NSusername";
        "password"="$NSpassword";
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/login" -body $body -SessionVariable NSSessionID `
-Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.login+json"} -Method POST
$Script:NSSessionID = $local:NSSessionID
}



function SetSNIP ($SNIPaddr, $SNMask) {
<#
    .SYNOPSIS
        Configure Subnet IP-Address( SNIP)
    .PARAMETER SNIP (Mandatory)
        SNIP IP-address.
    .PARAMETER SNMask (Mandatory)
        SNIP Subnetmask.
#>
$body = ConvertTo-JSON @{
    "nsip"=@{
        "ipaddress"="$SNIPaddr";
        "netmask"="$SNMask";
        "type"="SNIP";
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/nsip?action=add" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.nsip+json"} -Method POST
}



function SetTimeZone ($NSTimeZone) {
<#
    .SYNOPSIS
        Configure Time Zone
    .PARAMETER TimeZone (Mandatory)
        TimeZone to set.
#>
$body = ConvertTo-JSON @{
    "nsconfig"=@{
        "timezone"="$NSTimeZone";
        "cookieversion"="1";
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/nsconfig/nsconfig" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.nsconfig+json"} -Method PUT
}



function SetDNSServer ($DNSIP) {
<#
    .SYNOPSIS
        Configure DNS Server
    .PARAMETER DNSIP (Mandatory)
        IP-address of the DNS Server to be used.
#>
$body = ConvertTo-JSON @{
    "dnsnameserver"=@{
        "ip"="$DNSIP"
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/dnsnameserver?action=add" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.dnsnameserver+json"} -Method POST
}



function SetDNSSuffix ($DNSSuffix) {
<#
    .SYNOPSIS
        Configure DNS Suffix
    .PARAMETER DNSSuffix (Mandatory)
        DNS Suffix to be used for the DNS Server.
#>
$body = ConvertTo-JSON @{
    "dnssuffix"=@{
        "Dnssuffix"="$DNSSuffix"
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/dnssuffix?action=add" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.dnssuffix+json"} -Method POST
}



function SetNTPServer ($NTPServer) {
<#
    .SYNOPSIS
        Configure NTP Server
    .PARAMETER NTPServer (Mandatory)
        NTPServer can be a IP address (internal NTP) or a Hostname (external NTP).
#>

try {
    if ($NTPServer -eq [IPAddress]$NTPServer)
    { $body = ConvertTo-JSON @{
    "ntpserver"=@{
        "serverip"="$NTPServer"
        }
    } }
} catch {
    $body = ConvertTo-JSON @{
    "ntpserver"=@{
        "servername"="$NTPServer"
        }
    }
}
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/ntpserver?action=add" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.ntpserver+json"} -Method POST

# Enable Synchronisation
$body = ConvertTo-JSON @{
    "ntpsync"=@{}
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/ntpsync?action=enable" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.ntpsync+json"} -Method POST
}



function EnableModes ($NSModes) {
<#
    .SYNOPSIS
        Enable NetScaler Modes
    .PARAMETER NSModes (Mandatory)
        Modes to enable
#>
$NSModes = $NSModes -replace ",", " "

$body = ConvertTo-JSON @{
    "nsmode"=@{
        "mode"="$NSModes"
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/nsmode?action=enable" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.nsmode+json"} -Method POST
}



function EnableFeature ($NSfeature) {
<#
    .SYNOPSIS
        Enable NetScaler Features
    .PARAMETER NSFeatures (Mandatory)
        Features to enable
#>
$body = ConvertTo-JSON @{
    "nsfeature"=@{
        "feature"="$NSFeature"
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/nsfeature?action=enable" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.nsfeature+json"} -Method POST
}



function DisableCEIP {
<#
    .SYNOPSIS
        Disable Customer Experience Improvement Program
#>
$body = ConvertTo-JSON @{
    "systemparameter"=@{
        "doppler"="disabled"
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/systemparameter/systemparameter" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.systemparameter+json"} -Method PUT
}



function SetNSHTTPParams {
<#
    .SYNOPSIS
        Drop invalid HTTP requestes
#>
$body = ConvertTo-JSON @{
    "nshttpparam"=@{
        "dropinvalreqs"="ON";
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/nshttpparam/nshttpparam" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.nshttpparam+json"} -Method PUT
}



function SetNSTCPParams {
<#
    .SYNOPSIS
        Enable Windows Scaling & Selective Acknowledgement
#>
$body = ConvertTo-JSON @{
    "nstcpparam"=@{
        "ws"="ENABLED";
        "sack"="ENABLED";
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/nstcpparam/nstcpparam" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.nstcpparam+json"} -Method PUT
}



function CreateSystemGroup ($SGName) {
<#
    .SYNOPSIS
        Create a System Group for LDAP authentication
    .PARAMETER SGName (Mandatory)
        Name of the System Group
#>
$body = ConvertTo-JSON @{
    "systemgroup"=@{
        "groupname"="$SGName";
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/systemgroup?action=add" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.systemgroup+json"} -Method POST

# Bind Command policy to System Group
$body = ConvertTo-JSON @{
    "systemgroup_systemcmdpolicy_binding"=@{
        "groupname"="$SGName";
        "policyname"="superuser";
        "priority"=100;
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/systemgroup_systemcmdpolicy_binding/$SGName" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.systemgroup_systemcmdpolicy_binding+json"} -Method PUT
}



function CreateLDAPvServer ($VSRVName, $VSRVIP, $VSRVPort, $VSRVbaseDN, $VSRVbindDN, $VSRVBindPassword, $secure) {
<#
    .SYNOPSIS
        Create a LDAP authentication server
    .PARAMETER VSRVName (Mandatory)
        Name of the virtual server
    .PARAMETER VSRVIP (Mandatory)
        IP-address of the Domain Controller
    .PARAMETER VSRVPort (Mandatory)
        LDAP Port (389 unsecure, 686 secure)
    .PARAMETER VSRVbaseDN (Mandatory)
        BaseDN of the LDAP directory (dc=company,dc=local)
    .PARAMETER VSRVbindDN (Mandatory)
        Service user (read access to AD)
    .PARAMETER VSRVBindPassword (Mandatory)
        Password of the service user (ATTENTION it's readable in the script)
    .PARAMETER secure (Mandatory)
        $true (LDAP/S) or $false (LDAP)
#>
$body = @{
    "authenticationldapaction"=@{
        "name"="$VSRVName";
        "ServerIP"="$VSRVIP";
        "ServerPort"="$VSRVPort";
        "ldapbase"="$VSRVbaseDN";
        "ldapbinddn"="$VSRVbindDN";
        "ldapBindDnPassword"=$BindPassword;
        "ldaploginname"="sAMAccountname";
        "groupattrname"="memberOf";
        "subattributename"="CN";
        "sectype"="PLAINTEXT";
        }
    }

if ($secure -eq $true) { 
    $body.authenticationldapaction.sectype = "SSL"
    $body.authenticationldapaction.passwdchange = "enabled"
}

$body = ConvertTo-JSON $body
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/authenticationldapaction?action=add" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.authenticationldapaction+json"} -Method POST
}



function CreateLDAPPolicy ($LDAPPolicyName, $vSRVName) {
<#
    .SYNOPSIS
        Create a LDAP policy
    .PARAMETER LDAPPolicyName (Mandatory)
        Name of the LDAP policy
    .PARAMETER vSRVName (Mandatory)
        Name of the corresponding vServer
#>
$body = ConvertTo-JSON @{
    "authenticationldappolicy"=@{
        "name"="$LDAPPolicyName";
        "rule"="ns_true";
        "reqaction"="$vSRVName";
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/authenticationldappolicy?action=add" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.authenticationldappolicy+json"} -Method POST
}



function CreateGlobalLDAPBinding ($LDAPPolicyName) {
<#
    .SYNOPSIS
        Create a LDAP policy global binding
    .PARAMETER LDAPPolicyName (Mandatory)
        Name of the LDAP policy to bind
#>
$body = ConvertTo-JSON @{
    "systemglobal_authenticationldappolicy_binding"=@{
        "policyname"="$LDAPPolicyName";
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/systemglobal_authenticationldappolicy_binding/$LDAPPolicyName" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.systemglobal_authenticationldappolicy_binding+json"} -Method PUT
}



function CreateSFMonitor ($MonitorName, $SFStore, $secure) {
<#
    .SYNOPSIS
        Create a Storefront LB Monitor
    .PARAMETER MonitorName (Mandatory)
        Name of the monitor
    .PARAMETER SFStore (Mandatory)
        Path to the Storefront Store
    .PARAMETER secure (Mandatory)
        HTTP ($false), HTTPS ($true)
#>
$body = @{
    "lbmonitor"=@{
        "monitorname"="$MonitorName";
        "type"="STOREFRONT";
        "scriptname"="nssf.pl";
        "dispatcherip"="127.0.0.1";
        "dispatcherport"="3013";
        "storename"="$SFStore";
        "storefrontacctservice"="YES";
        }
    }
if ($secure -eq $true) {
    $body.lbmonitor.secure = "YES"
    }
$body = ConvertTo-JSON $body
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/lbmonitor?action=add" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.lbmonitor+json"} -Method POST
}



function CreateServiceGroup ($SGName, $SGType, $SGMonitor) {
<#
    .SYNOPSIS
        Create a Load Balancing Service Group
    .PARAMETER SGName (Mandatory)
        Name of the Service Group
    .PARAMETER SGType (Mandatory)
        Service Group type 
    .PARAMETER SGMonitor (Mandatory)
        Name of the corresponding monitor
#>
$body = ConvertTo-JSON @{
    "servicegroup"=@{
        "servicegroupname"="$SGName";
        "servicetype"="$SGType";
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/servicegroup?action=add" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.servicegroup+json"} -Method POST

# Bind monitor to the service group
if ($Monitor -ne $NULL) {
    $body = ConvertTo-JSON @{
        "servicegroup_lbmonitor_binding"=@{
            "servicegroupname"="$SGName";
            "monitor_name"="$SGMonitor";
            }
        }
    Invoke-RestMethod -uri "$NShostname/nitro/v1/config/servicegroup_lbmonitor_binding/$Name" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.servicegroup_lbmonitor_binding+json"} -Method PUT
    }
}



function CreateServiceGroupMember ($SvcGrpName, $ServerObject, $ServerIP, $ServerPort) {
<#
    .SYNOPSIS
        Create a Server Object used in Service Group
    .PARAMETER SvcGrpName (Mandatory)
        Name of the Service Group
    .PARAMETER ServerObject (Mandatory)
        Name of the Server Object 
    .PARAMETER ServerIP (Mandatory)
        IP-Address for the Server Object
    .PARAMETER ServerPort (Mandatory)
        Port of the Server Object
#>
# Check if Server Object already exist, if not create Server Object
try { 
    $response = Invoke-RestMethod -uri "$NShostname/nitro/v1/config/server/$ServerObject" -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.server+json"} -Method GET
} catch {
    $body = ConvertTo-JSON @{
        "server"=@{
            "name"="$ServerObject";
            "ipaddress"="$ServerIP";
            }
        }
    Invoke-RestMethod -uri "$NShostname/nitro/v1/config/server?action=add" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.server+json"} -Method POST
    }


# Bind server object to Service Group
$body = ConvertTo-JSON @{
    "servicegroup_servicegroupmember_binding"=@{
        "servicegroupname"="$SvcGrpName";
        "servername"="$ServerObject";
        "port"=$ServerPort;
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/servicegroup_servicegroupmember_binding/$SvcGrpName" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.servicegroup_servicegroupmember_binding+json"} -Method PUT
}



function CreateLBvServer ($LBvServerName, $LBvServerType, $LBvServerIP, $LBvServerPort) {
<#
    .SYNOPSIS
        Create a Server Object used in Service Group
    .PARAMETER LBvServerName (Mandatory)
        Name of the virtual Server
    .PARAMETER LBvServerType (Mandatory)
        Type of the virtual Server 
    .PARAMETER LBvServerIP (Mandatory)
        IP-Address for the virtual Server
    .PARAMETER LBvServerPort (Mandatory)
        Port of the virtual Server (80 or 443)
#>
$body = ConvertTo-JSON @{
    "lbvserver"=@{
        "name"="$LBvServerName";
        "servicetype"="$LBvServerType";
        "ipv46"="$LBvServerIP";
        "Port"="$LBvServerPort";
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/lbvserver?action=add" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.lbvserver+json"} -Method POST
}



function AddLBvServerSvcGrp ($vSRVName, $SvcGrpName) {
<#
    .SYNOPSIS
        Bind virtual Server to Service Group
    .PARAMETER vSRVName (Mandatory)
        Name of the virtual Server
    .PARAMETER SvcGrpName (Mandatory)
        Type of the Service Group 
#>
# Bind Service Group to vServer
$body = ConvertTo-JSON @{
    "lbvserver_servicegroup_binding"=@{
        "name"="$vSRVName";
        "servicegroupname"="$SvcGrpName";
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/lbvserver_servicegroup_binding/$Name" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.lbvserver_servicegroup_binding+json"} -Method PUT
}



function AddLBvServerPersist ($LBvSrvName, $LBvSrvType, $LBvSrvTimeout) {
<#
    .SYNOPSIS
        Configure vServer persistence
    .PARAMETER LBvSrvName (Mandatory)
        Name of the virtual Server
    .PARAMETER LBvSrvType (Mandatory)
        Persistance Type (normally SOURCEIP)
    .PARAMETER LBvSrvTimeout (Mandatory)
        Timeout if not provided 0
#> 
if ($Timeout -eq $null) { $LBvSrvTimeout = 2 }
$body = ConvertTo-JSON @{
    "lbvserver"=@{
        "name"="$LBvSrvName";
        "persistencetype"="$LBvSrvType";
        
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/lbvserver/$LBvSrvName" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.lbvserver+json"} -Method PUT

}



function CopySSLCertFiles ($NSHostIP, $NSUser, $NSPassword, $NSCertFileName, $NSKeyFileName) {
<#
    .SYNOPSIS
        Copy certifcate files to the NetScaler appliance
    .PARAMETER NSHostIP (Mandatory)
        IP-address (NSIP) of the NetScaler
    .PARAMETER NSUser (Mandatory)
        Superuser name (at this point it should be nsroot)
    .PARAMETER NSPassword (Mandatory)
        Superuser Password (at this point it should be nsroot)
    .PARAMETER NSCertFileName (Mandatory)
        Name of the certifcate file (must be in the script directory)
    .PARAMETER NSKeyFileName (Mandatory)
        Name of the private key file (must be in the script directory)
#>
# Check if Windows Management Framework 5 is installed (https://www.microsoft.com/en-us/download/details.aspx?id=50395)
If ($PSVersionTable.PSVersion.Major -ne 5) {
    Write-Warning -Message "Windows Management Framework 5 not installed. Please install WMF 5 before proceed - https://www.microsoft.com/en-us/download/details.aspx?id=50395"
    }

# Install SSH Module - https://github.com/darkoperator/Posh-SSH/blob/master/Readme.md
# Install-Module PoSH-SSH 

$NSCertFilePath = "$PSScriptRoot\$NSCertFileName"
$NSCertKeyPath = "$PSScriptRoot\$NSKeyFileName"
$NSSecureStringPwd = ConvertTo-SecureString $NSPassword -asplaintext -force
$NSCred = new-object management.automation.pscredential $NSUser,$NSSecureStringPwd

# Copy Certificate files with SCP to the NetScaler
try {
    
    Set-SCPFile -ComputerName $NSHostIP -Credential $NSCred -LocalFile $NSCertFilePath -RemotePath "/nsconfig/ssl/" -AcceptKey $True
    Set-SCPFile -ComputerName $NSHostIP -Credential $NSCred -LocalFile $NSCertKeyPath -RemotePath "/nsconfig/ssl/" -AcceptKey $True
    }
catch {

    $ErrorMessage = $_.Exception.Message
    $FailedItem = $_.Exception.ItemName
    Write-Warning "File copy failed. $ErrorMessage $FailedItem"

    }

}



function InstallSSLCert ($NSCErtName, $CertFile, $KeyFile, $KeyPassword) {
<#
    .SYNOPSIS
        Install SSL certificate
    .PARAMETER NSCErtName (Mandatory)
        Name of the Certificate
    .PARAMETER CertFile (Mandatory)
        Name of the Certificate file
    .PARAMETER KeyFile (Mandatory)
        Timeout if not provided 0
    .PARAMETER KeyPassword (Mandatory)
        Timeout if not provided 0
#>
$body = ConvertTo-JSON @{
    "sslcertkey"=@{
        "certkey"="$NSCErtName";
        "cert"="$CertFile";
        "key"="$KeyFile";
        "passplain"="$KeyPassword";
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/sslcertkey?action=add" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.sslcertkey+json"} -Method POST
}



function AddCipher ($CipherGroupName, $Cipher) {
<#
    .SYNOPSIS
        Add Cipher to Cipher Group
    .PARAMETER CipherGroupName (Mandatory)
        Name of the cipher group
#>
$body = @{
    "sslcipher_binding"=[ordered]@{
        "ciphergroupname"="$CipherGroupName";
        "ciphername"="$Cipher";
        }
    }
$body = ConvertTo-JSON $body
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/sslcipher_binding/$CipherGroupName" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.sslcipher_binding+json"} -Method PUT
}



function AddCipherGroup ($CipherGroupName) {
<#
    .SYNOPSIS
        Create Cipher Group
    .PARAMETER CipherGroupName (Mandatory)
        Name of the cipher group
#>
$body = @{
    "sslcipher"=@{
        "ciphergroupname"="$CipherGroupName";
        }
    }
$body = ConvertTo-JSON $body
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/sslcipher?action=add" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.sslcipher+json"} -Method POST

# Add best practice cipher to Cipher Group. No guarantee for completeness, feel free to add more.
# Make sure you read https://www.citrix.com/blogs/2016/06/09/scoring-an-a-at-ssllabs-com-with-citrix-netscaler-2016-update/
AddCipher $CipherGroupName TLS1-ECDHE-RSA-AES256-SHA
AddCipher $CipherGroupName TLS1-ECDHE-RSA-AES128-SHA
AddCipher $CipherGroupName TLS1-DHE-RSA-AES-256-CBC-SHA
AddCipher $CipherGroupName TLS1-DHE-RSA-AES-128-CBC-SHA
AddCipher $CipherGroupName TLS1-AES-256-CBC-SHA
AddCipher $CipherGroupName TLS1-AES-128-CBC-SHA
AddCipher $CipherGroupName SSL3-DES-CBC3-SHA
}



function AddSSLvServerCert ($vSRVName, $vSRVCert) {
<#
    .SYNOPSIS
        Add SSL cert to vServer
    .PARAMETER vSRVName (Mandatory)
        Name of the virtual server to bind the certificate
    .PARAMETER vSRVCert (Mandatory)
        Name of the certificate
#>
$body = ConvertTo-JSON @{
    "sslvserver_sslcertkey_binding"=@{
        "vservername"="$vSRVName";
        "certkeyname"="$vSRVCert";
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/sslvserver_sslcertkey_binding/$vSRVName" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.sslvserver_sslcertkey_binding+json"} -Method PUT
}



function AddSSLvServerCipher ($vSRVName, $CipherGroupName) {
<#
    .SYNOPSIS
        Add cipher group to virtual server
    .PARAMETER vSRVName (Mandatory)
        Name of the virtual server
    .PARAMETER CipherGroupName (Mandatory)
        Name of the cipher group
#>
# Delete default cipher group binding
Invoke-RestMethod -uri ("$NShostname/nitro/v1/config/sslvserver_sslciphersuite_binding/$vSRVName" + "?args=cipherName:DEFAULT") -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.sslvserver_sslciphersuite_binding+json"} -Method DELETE

# Add cipher group
$body = ConvertTo-JSON @{
    "sslvserver_sslciphersuite_binding"=@{
        "vservername"="$vSRVName";
        "ciphername"="$CipherGroupName";
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/sslvserver_sslciphersuite_binding/$vSRVName" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.sslvserver_sslciphersuite_binding+json"} -Method PUT
}



function DisableSSLv3 ($vSRVName) {
<#
    .SYNOPSIS
        Disable SSLv3
    .PARAMETER vSRVName (Mandatory)
        Name of the virtual Server
#>
$body = ConvertTo-JSON @{
    "sslvserver"=@{
        "vservername"="$vSRVName";
        "ssl3"="DISABLED";
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/sslvserver/$vSRVName" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.sslvserver+json"} -Method PUT
}



function CreateSessionPolicies ($SFFQDN, $SFStore, $SFSSODomain) {
<#
    .SYNOPSIS
        Create default ICA session policies
    .PARAMETER SFFQDN (Mandatory)
        FQDN of the Storefront server
    .PARAMETER SFStore (Mandatory)
        Name of the store (without "Web")
    .PARAMETER SFSSODomain (Mandatory)
        Single sign on domain for Storefront
#>
$body = ConvertTo-JSON @{
    "vpnsessionaction"=@{
        "name"="Receiver for Web";
        "clientlessvpnmode"="off";
        "transparentinterception"="off";
        "defaultauthorizationaction"="ALLOW";
        "sso"="ON";
        "icaproxy"="ON";
        "wihome"="http://$SFFQDN/Citrix/$SFStore"+"Web";
        "ntdomain"="$SFSSODomain";
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/vpnsessionaction?action=add" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.vpnsessionaction+json"} -Method POST

$body = ConvertTo-JSON @{
    "vpnsessionaction"=@{
        "name"="Receiver Self-Service";
        "clientlessvpnmode"="off";
        "transparentinterception"="off";
        "defaultauthorizationaction"="ALLOW";
        "sso"="ON";
        "icaproxy"="ON";
        "wihome"="http://$SFFQDN";
        "ntdomain"="$SFSSODomain";
        "storefronturl"="http://$SFFQDN";
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/vpnsessionaction?action=add" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.vpnsessionaction+json"} -Method POST

$body = ConvertTo-JSON @{
    "vpnsessionpolicy"=@{
        "name"="Receiver for Web";
        "rule"="REQ.HTTP.HEADER User-Agent NOTCONTAINS CitrixReceiver";
        "action"="Receiver for Web";
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/vpnsessionpolicy?action=add" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.vpnsessionpolicy+json"} -Method POST

$body = ConvertTo-JSON @{
    "vpnsessionpolicy"=@{
        "name"="Receiver Self-Service";
        "rule"="REQ.HTTP.HEADER User-Agent CONTAINS CitrixReceiver";
        "action"="Receiver Self-Service";
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/vpnsessionpolicy?action=add" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.vpnsessionpolicy+json"} -Method POST
}



function CreateGatewayvServer ($NSGFQDN, $NSGVIP, $STA) {
<#
    .SYNOPSIS
        Create the NetScaler Gateway virtual server
    .PARAMETER NSGFQDN (Mandatory)
        FQDN of the NSG vServer
    .PARAMETER NSGVIP (Mandatory)
        IP-address of the NSG vServer
    .PARAMETER STA (Mandatory)
        FQDN of the STA server(s)
#>
$body = ConvertTo-JSON @{
    "vpnvserver"=@{
        "name"="$NSGFQDN";
        "servicetype"="SSL";
        "ipv46"="$NSGVIP";
        "port"="443";
        "icaonly"="ON";
        "tcpprofilename"="nstcp_default_XA_XD_profile";
        "dtls"="ON";
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/vpnvserver?action=add" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.vpnvserver+json"} -Method POST

# Bind session policies 
$body = ConvertTo-JSON @{
    "vpnvserver_vpnsessionpolicy_binding"=@{
        "name"="$NSGFQDN";
        "policy"="Receiver Self-Service";
        "priority"=100;
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/vpnvserver_vpnsessionpolicy_binding/$NSGFQDN" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.vpnvserver_vpnsessionpolicy_binding+json"} -Method PUT

$body = ConvertTo-JSON @{
    "vpnvserver_vpnsessionpolicy_binding"=@{
        "name"="$NSGFQDN";
        "policy"="Receiver for Web";
        "priority"=110;
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/vpnvserver_vpnsessionpolicy_binding/$NSGFQDN" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.vpnvserver_vpnsessionpolicy_binding+json"} -Method PUT

# Bind Secure Ticket Authority
$STA = $STA.split(",")
foreach ($STA in $STA) {
    $body = ConvertTo-JSON @{
        "vpnvserver_staserver_binding"=@{
            "name"="$NSGFQDN";
            "staserver"="$STA";
            }
        }
    Invoke-RestMethod -uri "$NShostname/nitro/v1/config/vpnvserver_staserver_binding/$NSGFQDN" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.vpnvserver_staserver_binding+json"} -Method PUT
    }

# Bind Portal Theme to NSG.
$body = ConvertTo-JSON @{
        "vpnvserver_vpnportaltheme_binding"=@{
        "name"="$NSGFQDN";
        "portaltheme"="X1";
            }
        }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/vpnvserver_vpnportaltheme_binding/$NSGFQDN" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.vpnvserver_vpnportaltheme_binding+json"} -Method PUT
    
}



function CreateGatewayvServerAuth ($NSGFQDN, $LDAPPolicyName) {
<#
    .SYNOPSIS
        Bind LDAP Policy to NSG
    .PARAMETER NSGFQDN (Mandatory)
        FQDN of the NSG vServer
    .PARAMETER LDAPPolicyName (Mandatory)
        Name of the LDAP Policy
#>
$body = ConvertTo-JSON @{
    "vpnvserver_authenticationldappolicy_binding"=@{
        "name"="$NSGFQDN";
        "policy"="$LDAPPolicyName";
        "priority"=100;
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/vpnvserver_authenticationldappolicy_binding/$NSGFQDN" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.vpnvserver_authenticationldappolicy_binding+json"} -Method PUT
}



function SaveConfig {
<#
    .SYNOPSIS
        Save configuration
#>
$body = ConvertTo-JSON @{
    "nsconfig"=@{
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/nsconfig?action=save" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.nsconfig+json"} -Method POST
}



function NSLogout {
<#
    .SYNOPSIS
        Logout from NetScaler
#>
$body = ConvertTo-JSON @{
    "logout"=@{
        }
    }
Invoke-RestMethod -uri "$NShostname/nitro/v1/config/logout" -body $body -WebSession $NSSessionID -Headers @{"Content-Type"="application/vnd.com.citrix.netscaler.logout+json"} -Method POST
}

#########################################################################################################
# END - Function Block
#########################################################################################################

# Start Main Script

# Clear NS Session ID to make sure we start fresh and clean.
$NSSessionID = ""

# Login to NetScaler Appliance
Write-Progress -activity "Configure NetScaler" -status "Login" -percentComplete 2
NSLogin

# Configure NetScaler SNIP
Write-Progress -activity "Configure NetScaler" -status "Configure SNIP" -percentComplete 4
SetSNIP $SNIP $SNIPMask

# Configure basic system parameter
Write-Progress -activity "Configure NetScaler" -status "Set Basic Parameter" -percentComplete 12
SetTimeZone $NSTimeZone
SetDNSServer $DNSServer
SetDNSSuffix $DNSSuffix
SetNTPServer $NTPServer

# Configure Basic Settings
Write-Progress -activity "Configure NetScaler" -status "Set Basic Parameter" -percentComplete 20
DisableCEIP
SetNSHTTPParams
SetNSTCPParams

# Enable NetScaler Modes
Write-Progress -activity "Configure NetScaler" -status "Enable Modes" -percentComplete 22
EnableModes mbf 

# Enable NetScaler Features
Write-Progress -activity "Configure NetScaler" -status "Enable features" -percentComplete 28
EnableFeature lb
EnableFeature ssl
EnableFeature sslvpn

# Add New Super User Group & bind command policy. Group must be created in AD (case sensitiv) as well.
Write-Progress -activity "Configure NetScaler" -status "Create System Group" -percentComplete 30
CreateSystemGroup NetScalerAdmins

# Create LDAP Authentication Server
Write-Progress -activity "Configure NetScaler" -status "Create LDAP Server" -percentComplete 32
CreateLDAPvServer "vSRV_ldap_intern" $DCServerIP 636 $DCBaseDN $DCBindDNName $DCBindDNPass -secure $True

    # If you prefere a unsecured connection uncomment the line below and comment the line above
    # CreateLDAPvServer "vSRV_ldap_intern" $DCServerIP 389 $DCBaseDN $DCBindDNName $DCBindDNPass -secure $False

# Create LDAP Policy
Write-Progress -activity "Configure NetScaler" -status "Create LDAP Policy" -percentComplete 35
CreateLDAPPolicy "pol_ldap_intern" "vSRV_ldap_intern"

# Bind LDAP Policy global
Write-Progress -activity "Configure NetScaler" -status "Bind Policy Global" -percentComplete 38
CreateGlobalLDAPBinding "pol_ldap_intern"

# SSL Certifcate
Write-Progress -activity "Configure NetScaler" -status "Install SSL Certifcates" -percentComplete 45
AddCipherGroup Modern
CopySSLCertFiles $NSIP $NSusername $NSpassword $vSRVCertFile $vSRVCertKey
InstallSSLCert $vSRVCertName $vSRVCertFile $vSRVCertKey $vSRVCertKeyPass

# If there is an internal SSL certificate as well
# CopySSLCertFiles $NSIP $NSusername $NSpassword $vSRVCertFileInt $vSRVCertKeyInt
# InstallSSLCert $vSRVCertNameInt $vSRVCertFileInt $vSRVCertKeyInt $vSRVCertKeyPassInt

# StoreFront Load Balancing
Write-Progress -activity "Configure NetScaler" -status "Create Storefront Load Balancing" -percentComplete 60
$LBSvcGrpName ="svc-grp_StoreFront"
$LBvServerName = "vSRV_LB_SF_SSL"
$LBMonitorName = "StoreFront"

    # Unsecure 
    CreateSFMonitor $LBMonitorName Store -secure $False
    CreateServiceGroup $LBSvcGrpName HTTP $LBMonitorName
    CreateServiceGroupMember $LBSvcGrpName $SFServer $SFServerIP 80
    CreateLBvServer $LBvServerName HTTP $SFVIP 80
    AddLBvServerSvcGrp $LBvServerName $LBSvcGrpName
    AddLBvServerPersist $LBvServerName SOURCEIP 

    # Secure 
    # CreateSFMonitor $LBMonitorName Store -secure $True
    # CreateServiceGroup $LBSvcGrpName SSL $LBMonitorName
    # CreateServiceGroupMember $LBSvcGrpName $SFServer $SFServerIP 443
    # CreateLBvServer $LBvServerName SSL $SFVIP 443
    # AddLBvServerSvcGrp $LBvServerName $LBSvcGrpName
    # AddSSLvServerCert $LBvServerName $vSRVCertNameInt
    # AddSSLvServerCipher $LBvServerName Modern
    # DisableSSLv3 $LBvServerName
    # AddLBvServerPersist $LBvServerName SOURCEIP 120

# NetScaler Gateway
Write-Progress -activity "Configure NetScaler" -status "NetScaler Gateway" -percentComplete 96
CreateSessionPolicies $SFVIP Store myctxlab
CreateLDAPvServer "vSRV_ldap_extern" $DCServerIP 636 $DCBaseDN $DCBindDNName $DCBindDNPass -secure $True
CreateLDAPPolicy "pol_ldap_extern" "vSRV_ldap_extern"
CreateGatewayvServer $GatewayFQDN $GWVIP $GatewaySTA
CreateGatewayvServerAuth $GatewayFQDN "pol_ldap_extern"
AddSSLvServerCert $GatewayFQDN $vSRVCertName
AddSSLvServerCipher $GatewayFQDN Modern 
DisableSSLv3 $GatewayFQDN

# Save configuration
SaveConfig
Write-Progress -activity "Configure NetScaler" -status "Save Config" -percentComplete 98

# Logout from NetScaler appliance
NSLogout
Write-Progress -activity "Configure NetScaler" -status "Logout" -completed

# End of the Magic !!!!
