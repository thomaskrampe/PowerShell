<#
    .SYNOPSIS
        Register NetScaler Gateway in Storefront.
    .DESCRIPTION
        Register NetScaler Gateway in Storefront via Powershell remoting. This script should run on the Automation Machine itself.
    .PARAMETER StoreVirtualPath (Mandatory)
        The Path to the Storefront Store (eg. /Citrix/Store).
    .PARAMETER GatewayURL (Mandatory)
        The external URL of the NetScaler Gateway vServer (starting with https://).
        For AM deployments use $env:NSGWFQDN
    .PARAMETER GatewayCallbackURL (Mandatory)
        Callback URL normally the same like the GatewayURL.
        For AM deployments use $env:NSGWFQDN
    .PARAMETER GatewaySTAUrls (Mandatory)
        The URL of the STA server, normally the DDC. 
        For AM deployments use $env:NSGWSTA
    .PARAMETER GatewaySubnetIP
        SNIP or MIP address (10.0) or VIP address (10.5 >) for the Gateway.
        For AM deployments use $env:NSGWVIP
    .PARAMETER GatewayName (Mandatory)
        NetScaler name in Storefront.
        For AM deployments use $env:NSGWName
    .PARAMETER SFServerIP (Mandatory)
        IP address of the Storefront Server
        For AM deployments use $env:NSSFServerIP
    .NOTES
        Thomas Krampe - t.krampe@loginconsultants.de
        Version 1.0
#>

Param(
    [string]$StoreVirtualPath = "/Citrix/Store",
    [Uri]$GatewayUrl = "https://",
    [Uri]$GatewayCallbackUrl = "https://",
    [Uri[]]$GatewaySTAUrls = "https://",
    [string]$GatewaySubnetIP = "",
    [string]$GatewayName = "",
    [string]$SFServerIP = ""
)

Set-StrictMode -Version 2.0

if ($env:NSDCBindDN) {
    $DomainUserName = $env:NSDCBindDN.Split(";")[0]
    $DomainSecureStringPwd = ConvertTo-SecureString $env:NSDCBindDN.Split(";")[1] -asplaintext -force
    }
    else {
        $NSDCBinDN = Get-Credential
        $DomainUserName = $credential.getNetworkCredential().username
        $DomainSecureStringPwd = ConvertTo-SecureString $credential.getNetworkCredential().password -asplaintext -force
}

# Create the powershell credential object
$Cred = new-object management.automation.pscredential $DomainUserName,$DomainSecureStringPwd 

# Create the Powershell session
$Session = New-PSSession –Computername $SFServerIP -Credential $Cred

# Any failure is a terminating failure.
$ErrorActionPreference = 'Stop'
$ReportErrorShowStackTrace = $true
$ReportErrorShowInnerException = $true

Invoke-Command -Session $Session -argumentlist $StoreVirtualPath,$GatewayUrl,$GatewayCallbackUrl,$GatewaySTAUrls,$GatewaySubnetIP,$GatewayName -ScriptBlock {

    # Import StoreFront modules. Required for versions of PowerShell earlier than 3.0 that do not support autoloading
    Import-Module Citrix.StoreFront
    Import-Module Citrix.StoreFront.Stores
    Import-Module Citrix.StoreFront.Roaming

    # Determine the Authentication and Receiver sites based on the Store
    $store = Get-STFStoreService -VirtualPath $args[0]
    $authentication = Get-STFAuthenticationService -StoreService $store
    $receiverForWeb = Get-STFWebReceiverService -StoreService $store

    # Enables CitrixAGBasic on the Citrix Receiver for Web service required for remote access using NetScaler Gateway. 
    $receiverMethods = Get-STFWebReceiverAuthenticationMethodsAvailable | Where-Object { $_ -match "Explicit" -or $_ -match "CitrixAG" }

    # Enable CitrixAGBasic in Receiver for Web (required for remote access)
    Set-STFWebReceiverService $receiverForWeb 

    # Enables CitrixAGBasic on the authentication service. This is required for remote access.
    $citrixAGBasic = Get-STFAuthenticationProtocolsAvailable | Where-Object { $_ -match "CitrixAGBasic" }

    # Enable CitrixAGBasic in the Authentication service (required for remote access)
    Enable-STFAuthenticationServiceProtocol -AuthenticationService $authentication -Name $citrixAGBasic

    # Add a new Gateway used to access the new store remotely
    Add-STFRoamingGateway -Name $args[5] -LogonType Domain -Version Version10_0_69_4 -GatewayUrl $args[1] -CallbackUrl $args[2] -SecureTicketAuthorityUrls $args[3]

    # Get the new Gateway from the configuration (Add-STFRoamingGateway will return the new Gateway if -PassThru is supplied as a parameter)
    $gateway = Get-STFRoamingGateway -Name $args[5]

    # If the gateway subnet was provided then set it on the gateway object
    if($args[4])

    {

        Set-STFRoamingGateway -Gateway $gateway -SubnetIPAddress $args[4]

    }

    # Register the Gateway with the new Store
    Register-STFStoreGateway -Gateway $gateway -StoreService $store -DefaultGateway


}

Remove-PSSession $Session