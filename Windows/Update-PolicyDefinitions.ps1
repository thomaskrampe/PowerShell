# Standalone application install script for VDI environment - (C)2022 Jonathan Pitre, inspired by xenappblog.com

#Requires -Version 5.1
#Requires -RunAsAdministrator

#---------------------------------------------------------[Initialisations]--------------------------------------------------------

$ProgressPreference = "SilentlyContinue"
$ErrorActionPreference = "SilentlyContinue"
# Set the script execution policy for this process
Try { Set-ExecutionPolicy -ExecutionPolicy 'ByPass' -Scope 'Process' -Force } Catch {}
$env:SEE_MASK_NOZONECHECKS = 1
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[System.Net.WebRequest]::DefaultWebProxy.Credentials = [System.Net.CredentialCache]::DefaultCredentials
$Modules = @("PSADT") # Modules list

Function Get-ScriptDirectory
{
    Remove-Variable appScriptDirectory
    Try
    {
        If ($psEditor) { Split-Path $psEditor.GetEditorContext().CurrentFile.Path } # Visual Studio Code Host
        ElseIf ($psISE) { Split-Path $psISE.CurrentFile.FullPath } # Windows PowerShell ISE Host
        ElseIf ($PSScriptRoot) { $PSScriptRoot } # Windows PowerShell 3.0-5.1
        Else
        {
            Write-Host -Object "Cannot resolve script file's path" -ForegroundColor Red
            Exit 1
        }
    }
    Catch
    {
        Write-Host -Object "Caught Exception: $($Error[0].Exception.Message)" -ForegroundColor Red
        Exit 2
    }
}

Function Initialize-Module
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory = $true)]
        [string]$Module
    )
    Write-Host -Object "Importing $Module module..." -ForegroundColor Green

    # If module is imported say that and do nothing
    If (Get-Module | Where-Object { $_.Name -eq $Module })
    {
        Write-Host -Object "Module $Module is already imported." -ForegroundColor Green
    }
    Else
    {
        # If module is not imported, but available on disk then import
        If (Get-Module -ListAvailable | Where-Object { $_.Name -eq $Module })
        {
            $InstalledModuleVersion = (Get-InstalledModule -Name $Module).Version
            $ModuleVersion = (Find-Module -Name $Module).Version
            $ModulePath = (Get-InstalledModule -Name $Module).InstalledLocation
            $ModulePath = (Get-Item -Path $ModulePath).Parent.FullName
            If ([version]$ModuleVersion -gt [version]$InstalledModuleVersion)
            {
                Update-Module -Name $Module -Force
                Remove-Item -Path $ModulePath\$InstalledModuleVersion -Force -Recurse
                Write-Host -Object "Module $Module was updated." -ForegroundColor Green
            }
            Import-Module -Name $Module -Force -Global -DisableNameChecking
            Write-Host -Object "Module $Module was imported." -ForegroundColor Green
        }
        Else
        {
            # Install Nuget
            If (-not(Get-PackageProvider -ListAvailable -Name NuGet))
            {
                Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force
                Write-Host -Object "Package provider NuGet was installed." -ForegroundColor Green
            }

            # Add the Powershell Gallery as trusted repository
            If ((Get-PSRepository -Name "PSGallery").InstallationPolicy -eq "Untrusted")
            {
                Set-PSRepository -Name "PSGallery" -InstallationPolicy Trusted
                Write-Host -Object "PowerShell Gallery is now a trusted repository." -ForegroundColor Green
            }

            # Update PowerShellGet
            $InstalledPSGetVersion = (Get-PackageProvider -Name PowerShellGet).Version
            $PSGetVersion = [version](Find-PackageProvider -Name PowerShellGet).Version
            If ($PSGetVersion -gt $InstalledPSGetVersion)
            {
                Install-PackageProvider -Name PowerShellGet -Force
                Write-Host -Object "PowerShellGet Gallery was updated." -ForegroundColor Green
            }

            # If module is not imported, not available on disk, but is in online gallery then install and import
            If (Find-Module -Name $Module | Where-Object { $_.Name -eq $Module })
            {
                # Install and import module
                Install-Module -Name $Module -AllowClobber -Force -Scope AllUsers
                Import-Module -Name $Module -Force -Global -DisableNameChecking
                Write-Host -Object "Module $Module was installed and imported." -ForegroundColor Green
            }
            Else
            {
                # If the module is not imported, not available and not in the online gallery then abort
                Write-Host -Object "Module $Module was not imported, not available and not in an online gallery, exiting." -ForegroundColor Red
                EXIT 1
            }
        }
    }
}

# Get the current script directory
$appScriptDirectory = Get-ScriptDirectory

# Install and import modules list
Foreach ($Module in $Modules)
{
    Initialize-Module -Module $Module
}

#-----------------------------------------------------------[Functions]------------------------------------------------------------

Function Get-EvergreenAdmxVersion
{
    <#
    .SYNOPSIS
    Returns latest Version
    #>

    try
    {
        $GitHubRepo = "msfreaks/EvergreenAdmx"
        $Releases = "https://api.github.com/repos/$GitHubRepo/releases"
        Write-Verbose -Message "Determining latest EvergreenAdmx version..." -Verbose
        $Version = (Invoke-WebRequest -Uri $Releases -UseBasicParsing | ConvertFrom-Json)[0].tag_name
        return $Version
    }
    catch
    {
        Throw $_
    }
}

function Resolve-Uri
{
    <#
    .SYNOPSIS
        Resolves a URI and also returns the filename and last modified date if found.

    .DESCRIPTION
        Resolves a URI and also returns the filename and last modified date if found.

    .NOTES
        Site: https://packageology.com
        Author: Dan Gough
        Twitter: @packageologist

    .LINK
        https://github.com/DanGough/Nevergreen

    .PARAMETER Uri
        The URI resolve. Accepts an array of strings or pipeline input.

    .PARAMETER UserAgent
        Optional parameter to provide a user agent for Invoke-WebRequest to use. Examples are:

        Googlebot: 'Googlebot/2.1 (+http://www.google.com/bot.html)'
        Microsoft Edge: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/42.0.2311.135 Safari/537.36 Edge/12.246'

    .EXAMPLE
        Resolve-Uri -Uri 'http://somewhere.com/somefile.exe'

        Description:
        Returns the absolute redirected URI, filename and last modified date.
    #>
    [CmdletBinding(SupportsShouldProcess = $False)]
    param (
        [Parameter(
            Mandatory = $true,
            Position = 0,
            ValueFromPipeline,
            ValueFromPipelineByPropertyName)]
        [ValidatePattern('^(http|https)://')]
        [Alias('Url')]
        [String[]] $Uri,
        [Parameter(
            Mandatory = $false,
            Position = 1)]
        [String] $UserAgent
    )

    begin
    {
        $ProgressPreference = 'SilentlyContinue'
    }

    process
    {

        foreach ($UriToResolve in $Uri)
        {

            try
            {

                $ParamHash = @{
                    Uri              = $UriToResolve
                    Method           = 'Head'
                    UseBasicParsing  = $True
                    DisableKeepAlive = $True
                    ErrorAction      = 'Stop'
                }

                if ($UserAgent)
                {
                    $ParamHash.UserAgent = $UserAgent
                }

                $Response = Invoke-WebRequest @ParamHash

                if ($IsCoreCLR)
                {
                    $ResolvedUri = $Response.BaseResponse.RequestMessage.RequestUri.AbsoluteUri
                }
                else
                {
                    $ResolvedUri = $Response.BaseResponse.ResponseUri.AbsoluteUri
                }

                Write-Verbose "$($MyInvocation.MyCommand): URI resolved to: $ResolvedUri"

                #PowerShell 7 returns each header value as single unit arrays instead of strings which messes with the -match operator coming up, so use Select-Object:
                $ContentDisposition = $Response.Headers.'Content-Disposition' | Select-Object -First 1

                if ($ContentDisposition -match 'filename="?([^\\/:\*\?"<>\|]+)')
                {
                    $FileName = $matches[1]
                    Write-Verbose "$($MyInvocation.MyCommand): Content-Disposition header found: $ContentDisposition"
                    Write-Verbose "$($MyInvocation.MyCommand): File name determined from Content-Disposition header: $FileName"
                }
                else
                {
                    $Slug = [uri]::UnescapeDataString($ResolvedUri.Split('?')[0].Split('/')[-1])
                    if ($Slug -match '^[^\\/:\*\?"<>\|]+\.[^\\/:\*\?"<>\|]+$')
                    {
                        Write-Verbose "$($MyInvocation.MyCommand): URI slug is a valid file name: $FileName"
                        $FileName = $Slug
                    }
                    else
                    {
                        $FileName = $null
                    }
                }

                try
                {
                    $LastModified = [DateTime]($Response.Headers.'Last-Modified' | Select-Object -First 1)
                    Write-Verbose "$($MyInvocation.MyCommand): Last modified date: $LastModified"
                }
                catch
                {
                    Write-Verbose "$($MyInvocation.MyCommand): Unable to parse date from last modified header: $($Response.Headers.'Last-Modified')"
                    $LastModified = $null
                }

            }
            catch
            {
                Throw "$($MyInvocation.MyCommand): Unable to resolve URI: $($_.Exception.Message)"
            }

            if ($ResolvedUri)
            {
                [PSCustomObject]@{
                    Uri          = $ResolvedUri
                    FileName     = $FileName
                    LastModified = $LastModified
                }
            }

        }
    }

    end
    {
    }

}

function Get-MicrosoftAVDAdmx
{
    <#
    .SYNOPSIS
    Download latest version of the Microsoft AVD Admx files
#>

    $productname = "MicrosoftAVD"

    try
    {
        $ProgressPreference = 'SilentlyContinue'
        $URI = Resolve-Uri -Uri "https://aka.ms/avdgpo" | Select-Object -ExpandProperty Uri

        # download
        Write-Verbose "Downloading '$($URI)' to '$($CustomPolicyStore)'"
        Invoke-WebRequest -Uri $URI -UseBasicParsing -DisableKeepAlive -OutFile "$DownloadsDirectory\AVDGPTemplate.cab"

        # extract
        Start-Process -FilePath "$env:windir\system32\cmd.exe" -ArgumentList "/c expand.exe -F:* $DownloadsDirectory\AVDGPTemplate.cab $DownloadsDirectory\$productname.zip" -NoNewWindow
        Start-Sleep -Seconds 3
        Expand-Archive -Path "$DownloadsDirectory\$($productname).zip" -DestinationPath $CustomPolicyStore

        # cleanup
        Remove-Item -Path "$DownloadsDirectory\AVDGPTemplate.cab" -Force
    }
    catch
    {
        Throw $_
    }
}

function Get-SchannelAdmx
{
    <#
    .SYNOPSIS
    Download latest version of the Schannel Admx files
#>

    $productname = "Schannel"

    try
    {
        $ProgressPreference = 'SilentlyContinue'
        $URIAdmx = "https://raw.githubusercontent.com/Crosse/SchannelGroupPolicy/master/template/schannel.admx"
        $URIAdml = "https://raw.githubusercontent.com/Crosse/SchannelGroupPolicy/master/template/en-US/schannel.adml"

        # download
        Write-Verbose "Downloading '$($URI)' to '$($CustomPolicyStore)'"
        Invoke-WebRequest -Uri $URIAdmx -UseBasicParsing -DisableKeepAlive -OutFile "$CustomPolicyStore\$($productname).admx"
        Invoke-WebRequest -Uri $URIAdml -UseBasicParsing -DisableKeepAlive -OutFile "$CustomPolicyStore\en-US\$($productname).adml"
    }
    catch
    {
        Throw $_
    }
}

#----------------------------------------------------------[Declarations]----------------------------------------------------------

# Must read - https://techcommunity.microsoft.com/t5/core-infrastructure-and-security/windows-10-or-windows-11-gpo-admx-which-one-to-use-for-your/ba-p/3063322
$WindowsBuild = "22H2"
$Languages = @("en-US", "fr-FR")
$PolicyStore = "\\$envMachineADDomain\SYSVOL\$envMachineADDomain\Policies\PolicyDefinitions"
$IncludeProducts = @("Windows 10", "Microsoft Edge", "Microsoft OneDrive", "Microsoft Office", "FSLogix", "Adobe Acrobat", "Adobe Reader", "Citrix Workspace App", "Google Chrome", "Microsoft Desktop Optimization Pack", "Mozilla Firefox", "Zoom Desktop Client", "Custom Policy Store")
$WorkingDirectory = "C:\Scripts\EvergreenADMX"
$DownloadsDirectory = "$WorkingDirectory\downloads"
$CustomPolicyStore = "$WorkingDirectory\custom admx"
$CitrixADMXVersion = "2212"
$CitrixADMXUrl = "https://raw.githubusercontent.com/JonathanPitre/Scripts/master/Update-PolicyDefinitions/Citrix_$($CitrixADMXVersion).zip"
$CitrixADMX = Split-Path -Path $CitrixADMXUrl -Leaf
$latestEvergreenAdmxUrl = "https://raw.githubusercontent.com/msfreaks/EvergreenAdmx/5cc839cd89ff348ea979b30187ba56dfac423f74/EvergreenAdmx.ps1"
$latestEvergreenAdmx = Split-Path -Path $latestEvergreenAdmxUrl -Leaf

#-----------------------------------------------------------[Execution]------------------------------------------------------------

# Install EvergreenAdmx script - https://github.com/msfreaks/EvergreenAdmx
$EvergreenAdmxVersion = Get-EvergreenAdmxVersion

<#
$ScriptInfo = Get-InstalledScript | Where-Object { $_.Name -eq "EvergreenADMX" }
[boolean]$isScriptInstalled = [boolean]$ScriptInfo
If ($isScriptInstalled)
{
    $ScriptVersion = ($ScriptInfo).Version
    If ([version]$EvergreenAdmxVersion -eq [version]$ScriptVersion)
    {
        Write-Log -Message "EvergreenAdmx script is already installed!" -Severity 1 -LogType CMTrace -WriteHost $True
    }
}
Else
{
    Write-Log -Message "Installing latest EvergreenAdmx script..." -Severity 1 -LogType CMTrace -WriteHost $True
    Install-Script -Name EvergreenAdmx -Force -Scope AllUsers
    Invoke-WebRequest -Uri $latestEvergreenAdmxUrl -UseBasicParsing -OutFile "$envProgramFiles\WindowsPowerShell\Scripts\$latestEvergreenAdmx"
}
#>

Write-Log -Message "Installing latest EvergreenAdmx script..." -Severity 1 -LogType CMTrace -WriteHost $True
Install-Script -Name EvergreenAdmx -Force -Scope AllUsers
Invoke-WebRequest -Uri $latestEvergreenAdmxUrl -UseBasicParsing -OutFile "$envProgramFiles\WindowsPowerShell\Scripts\$latestEvergreenAdmx"

# Clean older files
If (Test-Path -Path "$WorkingDirectory\*")
{
    Write-Log -Message "Cleaning older files..." -Severity 1 -LogType CMTrace -WriteHost $True
    Remove-Folder -Path "$WorkingDirectory\downloads" -ContinueOnError $True
}

# Create folders structure
New-Folder -Path $WorkingDirectory
New-Folder -Path $DownloadsDirectory
New-Folder -Path $CustomPolicyStore
Set-Location -Path $WorkingDirectory
If (-Not(Test-Path $PolicyStore)) { New-Folder -Path $PolicyStore }

# Download custom Policy Definitions files
Write-Log -Message "Downloading custom Policy Definitions files..." -Severity 1 -LogType CMTrace -WriteHost $True
# Citrix
Invoke-WebRequest -UseBasicParsing -Uri $CitrixADMXUrl -OutFile "$WorkingDirectory\downloads\$CitrixADMX"
# Microsoft AVD
Get-MicrosoftAVDAdmx
# SChannel
Get-SchannelAdmx

# Extract custom Policy Definitions files
Write-Log -Message "Extracting custom Policy Definitions files..." -Severity 1 -LogType CMTrace -WriteHost $True

# Extract Citrix Policy Definitions files
Expand-Archive -Path "$DownloadsDirectory\$CitrixADMX" -DestinationPath $CustomPolicyStore -Force

# Remove older Citrix Profile Management policy definitions files
Remove-Item -Path $PolicyStore -Include ctxprofile*.admx, ctxprofile*.adml -Recurse -Force

# Copy Policy Definitions files to Central Policy Store
Set-Location -Path "$envProgramFiles\WindowsPowerShell\Scripts"

$Windows10 = New-Object System.Management.Automation.Host.ChoiceDescription '&Windows 10', 'Windows 10'
$Windows11 = New-Object System.Management.Automation.Host.ChoiceDescription '&Windows 11', 'Windows 11'
$options = [System.Management.Automation.Host.ChoiceDescription[]]($Windows10, $Windows11)
$title = 'Operating System'
$message = "Which Operating System are you using for most of your endpoints ?"
$result = $host.ui.PromptForChoice($title, $message, $options, 0)
if ($result -eq 0)
{
    $choice = "Windows 10"
    Write-Log -Message "Downloading and copying Policy Definitions files for $choice to Central Policy Store..." -Severity 1 -LogType CMTrace -WriteHost $True
    .\EvergreenAdmx.ps1 -Windows10Version $WindowsBuild -WorkingDirectory $WorkingDirectory -PolicyStore $PolicyStore -Languages $Languages -UseProductFolders -CustomPolicyStore $CustomPolicyStore -Include $IncludeProducts

}
elseif ($result -eq 1)
{
    $choice = "Windows 11'"
    Write-Log -Message "Downloading and copying Policy Definitions files for $choice to Central Policy Store..." -Severity 1 -LogType CMTrace -WriteHost $True
    .\EvergreenAdmx.ps1 -Windows11Version $WindowsBuild -WorkingDirectory $WorkingDirectory -PolicyStore $PolicyStore -Languages $Languages -UseProductFolders -CustomPolicyStore $CustomPolicyStore -Include $IncludeProducts

}
else
{
    $choice = "Try again"
}
"You have selected: {0}" -f $choice

# Cleanup Central Policy Store
Write-Log -Message "Cleaning Central Policy Store..." -Severity 1 -LogType CMTrace -WriteHost $True

# Fix for WinStoreUI.admx error https://docs.microsoft.com/en-us/troubleshoot/windows-server/group-policy/winstoreui-conflict-with-windows-10-1151-admx-file
Remove-File -Path $PolicyStore WinStoreUI.adm* -Recurse -ContinueOnError $True

# Remove non policy definitions files
Remove-Item -Path $PolicyStore -Exclude *.admx, *.adml, $Languages[0], $Languages[1] -Recurse -Force

# Remove older Office policy definitions files
Remove-Item -Path $PolicyStore -Include *12*.admx, *12*.adml, *13*.admx, *13*.adml, *14*.admx, *14*.adml, *15*.admx, *15*.adml -Recurse -Force

# Remove older Adobe policy definitions files
Remove-Item -Path $PolicyStore -Include Acrobat2017.admx, Acrobat2017.adml, AcrobatReader2017.admx, AcrobatReader2017.adml, Acrobat2020.admx, Acrobat2020.adml, AcrobatReader2020.admx, AcrobatReader2020.adml -Recurse -Force

Write-Log -Message "Policy Definitions files were updated successfully!" -Severity 1 -LogType CMTrace -WriteHost $True