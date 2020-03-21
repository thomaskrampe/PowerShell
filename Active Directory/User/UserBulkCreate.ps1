<#
.SYNOPSIS
    UserBulkCreate.ps1

.DESCRIPTION
    Lightweight Script for creating users with random password based on CSV in AD

.EXAMPLE
    Example CSV
    lastname,firstname
    Biedermann,Sven
    Blume,Olaf
    Bremer,Thomas

.NOTES
    Author        : Thomas Krampe | t.krampe@loginconsultants.de
    Version       : 1.0
    Creation date : 19.03.2020 | v0.1 | Initial script
                  : 19.03.2020 | v1.0 | Released
                      
    IMPORTANT NOTICE
    ----------------
    THIS SCRIPT IS PROVIDED "AS IS" WITHOUT WARANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
    ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT.
    LOGIN CONSULTANTS, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS OR OMISSIONS CONTAINED 
    HEREIN, NOT FOR DIRECT, INCIDENTIAL, CONSEQUENTIAL OR ANY OTHER DAMAGES RESULTING FROM FURNISHING,
    PERFORMANCE, OR USE OF THIS SCRIPT, EVEN IF LOGIN CONSULTANTS HAS BEEN ADVISED OF THE POSSIBILITY
    OF SUCH DAMAGES IN ADVANCE.

#>

# -------------------------------------------------------------------------------------------------
# Define global Error handling
# -------------------------------------------------------------------------------------------------
$global:ErrorActionPreference = "Stop"
if($verbose){ $global:VerbosePreference = "Continue" }

# -------------------------------------------------------------------------------------------------
# FUNCTIONS (don't change anything here)
# -------------------------------------------------------------------------------------------------
function TK_WriteLog {
    <#
        .SYNOPSIS
            Write text to log file
        .DESCRIPTION
            Write text to this script's log file
        .PARAMETER InformationType
            This parameter contains the information type prefix. Possible prefixes and information types are:
            I = Information
            S = Success
            W = Warning
            E = Error
            - = No status
        .PARAMETER Text
            This parameter contains the text (the line) you want to write to the log file. If text in the parameter is omitted, an empty line is written.
        .PARAMETER LogFile
            This parameter contains the full path, the file name and file extension to the log file (e.g. C:\Logs\MyApps\MylogFile.log)
        .EXAMPLE
            TK_WriteLog -$InformationType "I" -Text "Copy files to C:\Temp" -LogFile "C:\Logs\MylogFile.log"
            Writes a line containing information to the log file
        .EXAMPLE
            TK_WriteLog -$InformationType "E" -Text "An error occurred trying to copy files to C:\Temp (error: $($Error[0]))" -LogFile "C:\Logs\MylogFile.log"
            Writes a line containing error information to the log file
        .EXAMPLE
            TK_WriteLog -$InformationType "-" -Text "" -LogFile "C:\Logs\MylogFile.log"
            Writes an empty line to the log file
    #>
    [CmdletBinding()]
    Param( 
        [Parameter(Mandatory=$true, Position = 0)][ValidateSet("I","S","W","E","-",IgnoreCase = $True)][String]$InformationType,
        [Parameter(Mandatory=$true, Position = 1)][AllowEmptyString()][String]$Text,
        [Parameter(Mandatory=$true, Position = 2)][AllowEmptyString()][String]$LogFile
        )
     
    begin {
        }
     
    process {
        $DateTime = (Get-Date -format dd-MM-yyyy) + " " + (Get-Date -format HH:mm:ss)
     
        if ( $Text -eq "" ) {
            Add-Content $LogFile -value ("") 
        } Else {
            Add-Content $LogFile -value ($DateTime + " " + $InformationType.ToUpper() + " - " + $Text)
            }
        }
     
    end {
        }
    }

function TK_RandomChars($length, $characters) {
    <#
    .SYNOPSIS
    Create a string with random characters
    .DESCRIPTION
    Create a string with random characters
    .PARAMETER length
    String length
    .PARAMETER characters
    Characters to use
    .EXAMPLE
    TK_Get-RandomCharacters -length 5 -characters 'abcdefghiklmnoprstuvwxyz'
    #>
    
    $random = 1..$length | ForEach-Object { Get-Random -Maximum $characters.length }
    $private:ofs=""
    return [String]$characters[$random]
}
 
function TK_ScrambleString([string]$inputString){     
    <#
    .SYNOPSIS
    Scramble a string
    .DESCRIPTION
    Scramble a string
    .PARAMETER inputString
    String to scrable
    .EXAMPLE
    TK_Scramble-String "yhlfeE0("
    #>
    
    $characterArray = $inputString.ToCharArray()   
    $scrambledStringArray = $characterArray | Get-Random -Count $characterArray.Length     
    $outputString = -join $scrambledStringArray
    return $outputString 
}

function TK_Confirm-DomainAdmin {
    [cmdletbinding()]
    param (
        $UserName = $env:USERNAME
    )
    begin {
        $domainadmins = (Get-ADGroupMember 'domain admins').samaccountname
    }
    process {
        foreach ($user in $UserName) {
            if ($user -in $domainadmins) {
                Write-Verbose "$User is a member of the domain admins group"
                $domainadmin = $true
            } else {
                Write-Verbose "$User is not a member of the domain admins group"
                $domainadmin = $false
            }

            [pscustomobject]@{
                User = $user
                DomainAdmin = $domainadmin
            }
        }
    }
}

# -------------------------------------------------------------------------------------------------
# Log handling
# -------------------------------------------------------------------------------------------------
$LogDir = "C:\_Logs"
$ScriptName = "UserBulkCreate"
$LogFileName = "$ScriptName"+"_$mode.log"
$LogFile = Join-path $LogDir $LogFileName

# Create the log directory if it does not exist
if (!(Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType directory | Out-Null }

# Create new log file (overwrite existing one)
New-Item $LogFile -ItemType "file" -force | Out-Null

# -------------------------------------------------------------------------------------------------
# Install modules
# -------------------------------------------------------------------------------------------------
$Module = "ActiveDirectory"
if (Get-Module -ListAvailable -Name $Module) {
    TK_WriteLog -InformationType "I" -Text  "Module $Module available." -LogFile $LogFile
    Import-Module $Module -Force
} 
else {
    TK_WriteLog -InformationType "I" -Text  "Module $Module not available trying to install." -LogFile $LogFile
    if ($Module -eq "ActiveDirectory"){
        try{
            Add-WindowsFeature RSAT-AD-PowerShell
            Import-Module ActiveDirectory
        }
        catch{
            TK_WriteLog -InformationType "E" -Text  "Installing Module $Module failed." -LogFile $LogFile
            Exit 1
        }
    }    
}

# -------------------------------------------------------------------------------------------------
# Check user persmissions
# -------------------------------------------------------------------------------------------------
$IsAdmin = TK_Confirm-DomainAdmin
If (!($IsAdmin.DomainAdmin)) {
    TK_WriteLog -InformationType "E" -Text  "User $IsAdmin.User is not Domain Admin" -LogFile $LogFile
    Write-Host "ERROR: User running this script must be member of the domain admin group." -ForegroundColor Red
    Exit 
}

# -------------------------------------------------------------------------------------------------
# Initialize Variables
# -------------------------------------------------------------------------------------------------
$Domain = Get-ADDomain
$ADUsersCSV = Import-csv %temp%\aduser.csv
[string]$ADDomainName = $Domain.DNSRoot
[string]$ADDomainOU = $domain.UsersContainer
[Int]$Usercount = 0

# -------------------------------------------------------------------------------------------------
# Script starts here
# -------------------------------------------------------------------------------------------------
TK_WriteLog -InformationType "I" -Text "Start adding users to Active Directory domain $ADDomainName." -LogFile $LogFile
TK_WriteLog -InformationType "I" -Text "Using OU-Path $ADDomainOU." -LogFile $LogFile

foreach ($User in $ADUsersCSV) {
    $PDFirstname   = $User.firstname
    $PDLastname    = $User.lastname

    # Create Password string with 12 chars
    $PDpassword = TK_RandomChars -length 6 -characters 'abcdefghiklmnoprstuvwxyz'
    $PDpassword += TK_RandomChars -length 2 -characters 'ABCDEFGHKLMNOPRSTUVWXYZ'
    $PDpassword += TK_RandomChars -length 2 -characters '1234567890'
    $PDpassword += TK_RandomChars -length 2 -characters '!"§$%&/()=?}][{@#*+'

    # Scramble the password string
    $PDpassword = TK_ScrambleString $PDpassword

    # Create username
    $PDUsername = $PDFirstname.Substring(0,1).ToLower()+"."+ $PDLastname.ToLower()
    $PDUserUPN = $PDUsername+"@"+$ADDomainName

    #Check if the user account already exists in AD
    if (Get-ADUser -F {SamAccountName -eq $PDUsername}) {
        #If user does exist, output a warning message
        TK_WriteLog -InformationType "E" -Text  "A user account $PDUsername has already exist in Active Directory." -LogFile $LogFile
            }
       else {
            #If a user does not exist then create a new user account
            #Account will be created in the OU listed in the $ADDomainOU variable; don’t forget to change the domain name in the $ADDomainName variable
            TK_WriteLog -InformationType "I" -Text  "Create user $PDUsername ($PDFirstname $PDLastname) with password $PDpassword" -LogFile $LogFile
            $Usercount++

            New-ADUser `
            -SamAccountName $PDUsername `
            -UserPrincipalName $PDUserUPN `
            -Name "$PDFirstname $PDLastname" `
            -GivenName $PDFirstname `
            -Surname $PDLastname `
            -Enabled $True `
            -ChangePasswordAtLogon $True `
            -DisplayName "$PDLastname, $PDFirstname" `
            -Path $ADDomainOU `
            -AccountPassword (convertto-securestring $PDpassword -AsPlainText -Force)

       }
}

TK_WriteLog -InformationType "I" -Text  "Add users finished. $Usercount user accounts created." -LogFile $LogFile
