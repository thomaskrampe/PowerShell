<#
.SYNOPSIS This script verifies that a machine in the vNet has access to the internet and the domain speficied by the user is reachable and the credentials are correct.

.PARAMETER DomainName
The domain name to verify

.PARAMETER ServiceAccountName
The user account that has access to the domain

.PARAMETER ServiceAccountPassword
The password for the service account user

.EXAMPLE
VerifyReachability.ps1 -DomainName 'radhe.local' -ServiceAccountName 'skyway'  -ServiceAccountPassword 'citrix'
#>

param(
    [Parameter(Mandatory=$true)]
    [string] $DomainName,
    [Parameter(Mandatory=$true)]
    [string] $ServiceAccountName,
	[Parameter(Mandatory=$true)]
    [string] $ServiceAccountPassword	
)

Add-Type -TypeDefinition "
public enum ReachabilityStatus
{
    Success,
    ErrorNoInternetConnection,
    ErrorDomainNotReachable,
    ErrorIncorrectDomainCredentials   
}
"

function IamOnline {
<# 
 .SYNOPSIS
  Function/tool to detect if the computer has Internet access

 .DESCRIPTION
  Function/tool to detect if the computer has Internet access

 .EXAMPLE
  if (IamOnline) { "I'm online" } else { "I'm offline" }
  If any of the input URLs retuns a status code, 
  it's considered online and function returns a positive result

 .OUTPUTS
  A number ranging from zero to the count of URLs entered

 .LINK
  https://superwidgets.wordpress.com/category/powershell/

 .NOTES
  Function by Sam Boutros
  v1.0 - 12/19/2014

#>

    $urls = @('https://citrix.com','https://microsoft.com','https://google.com')
    $success = 0
    Foreach($uri in $urls) {
        try { 
            $response = Invoke-WebRequest -Uri $uri -UseBasicParsing -ErrorAction Stop
            if ($response.StatusCode) { $success++ }
        } catch {}
    }
    if ($success -eq 0)
    {
        return $false
    }
    return $true
}

function Test-ADCredentials {
    Param($username, $password, $domain)

    Add-Type -AssemblyName System.DirectoryServices.AccountManagement
    $ct = [System.DirectoryServices.AccountManagement.ContextType]::Domain
    $pc = New-Object System.DirectoryServices.AccountManagement.PrincipalContext($ct, $domain)
    $isValid = $pc.ValidateCredentials($username, $password)    
    return $isValid
}

function HandleDomainError {
    Param (
        [int]$currentCount,
        [int]$maxCount
    )
    if ($currentCount -ge $maxCount)
    {
        $errorCode = [ReachabilityStatus]::ErrorDomainNotReachable
        throw "CTX ERROR CODE:[$errorCode]: $_"
    }
    Start-Sleep -Seconds 60  
}

[Reflection.Assembly]::LoadWithPartialName("System.Web") | Out-Null

$isOnline = IamOnline
if (!($isOnline))
{ 
    $errorCode = [ReachabilityStatus]::ErrorNoInternetConnection
    throw "CTX ERROR CODE:[$errorCode]: Machines created in the specified vNet do not have internet connection. Please check DNS settings."
} 

$retryAttempt = 0
$maxRetryAttempt = 3
while($true)
{
    try 
    {
        $retryAttempt++
	    $decodedPassword = [System.Web.HttpUtility]::UrlDecode($ServiceAccountPassword)
	    $decodedDomain = [System.Web.HttpUtility]::UrlDecode($DomainName)
	    $decodedAccountName = [System.Web.HttpUtility]::UrlDecode($ServiceAccountName)
	 
        if ($decodedAccountName.Contains("\"))
        {
            $decodedAccountName = $decodedAccountName.Split("\")[1];
        }
        
        $isValidCredentials = Test-ADCredentials $decodedAccountName $decodedPassword $decodedDomain
        
        if ($isValidCredentials -ne $true)
        {			
            $errorCode = [ReachabilityStatus]::ErrorIncorrectDomainCredentials
            throw "CTX ERROR CODE:[$errorCode]: $_"
        }
        break;
    } catch {
        if ($Error[0] -ne $null -and $Error[0].Exception.Message.Contains("ErrorIncorrectDomainCredentials"))
        {			
            $errorCode = [ReachabilityStatus]::ErrorIncorrectDomainCredentials
            throw $_
        }
        else
        {			
            HandleDomainError $retryAttempt $maxRetryAttempt
        }
    }
}