#
# Install all the Visual C Redistributables silently
#

# Install prerequisites
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

# Install and Import PowerShell Module
Install-Module VcRedist -AllowClobber -Force
Import-Module VcRedist

# Create target path if not present
$Path = "C:\Temp\VcRedist"
if (!(Test-Path $Path))
    {
        New-Item -itemType Directory -Path C:\Temp\ -Name VcRedist
    }

# Download redistributables
$VcList = Get-VcList | Get-VcRedist -Path "C:\Temp\VcRedist"

# Install redistributables
$VcList | Install-VcRedist -Path C:\Temp\VcRedist



