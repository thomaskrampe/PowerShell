<#
.SYNOPSIS
    Create GPO XML Reports and compare them

.DESCRIPTION

.PARAMETER Domain
    Domain FQDN

.PARAMETER DC
        Hostname of the Domain Controller

.PARAMETER GPONames
        GPO names seperated by comma

.PARAMETER Folder
        Target folder for Reports

.PARAMETER User / Computer
        User or Computer part of the GPO

.EXAMPLE
        GPO-CompraeReports.ps1 -Domain "domain.local" -DC "domaincontroller" -GPONames "Policy1,Policy2" -Folder "C:\TEMP" -Computer
    
        or with pre-filled values

        GPO-CompareReports.ps1 -User | GPO-CompareReports.ps1 -computer

.LINK

.NOTES
        Author        : Thomas Krampe | t.krampe@loginconsultants.de
        Version       : 1.0
        Creation date : 14.08.2018 | v1.0 | Initial script
        Last change   :            |      | 

        IMPORTANT NOTICE
        ----------------
        THIS SCRIPT IS PROVIDED "AS IS" WITHOUT WARANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
        ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT.
        THOMAS KRAMPE, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS OR OMISSIONS CONTAINED 
        HEREIN, NOT FOR DIRECT, INCIDENTIAL, CONSEQUENTIAL OR ANY OTHER DAMAGES RESULTING FROM FURNISHING,
        PERFORMANCE, OR USE OF THIS SCRIPT, EVEN IF THOMAS KRAMPE HAS BEEN ADVISED OF THE POSSIBILITY
        OF SUCH DAMAGES IN ADVANCE.

#>

# Script parameters
Param(
    [string]$Domain = "domain.local",
    [string]$DC = "domaincontroller",
    [string]$GPONames = "GPO1,GPO2",
    [string]$Folder = "C:\_GPO_COMPARE",
    [switch]$User,
    [switch]$Computer
)

# Functions
Function GPOReport
    {
    Param(
        [string[]]$GPONames,
        [string]$Domain,
        [string]$DC,
        [string]$Folder
    )

    $GPOReport = $null

    ForEach($GPOName in $GPONames)
        {
            $Path = Join-Path -Path $Folder -ChildPath "$GPOName.xml"
            (Get-GPO -Name $GPOName -Domain $Domain -Server $DC).GenerateReportToFile("xml",$Path)
            [array]$GPOReport + $Path
        }
        Return $GPOReport
}

Function GPOCompare
    {
    Param(
        [string[]]$GPOReport,$User, $Computer
        )
    
    [xml]$xml1 = Get-Content -Path $GpoReport[0]
    [xml]$xml2 = Get-Content -Path $GpoReport[1]

    $GPOComputerNodes1 = $xml1.GPO.Computer.ExtensionData.Extension.ChildNodes | Select-Object name, state
    $GPOComputerNodes2 = $xml2.GPO.Computer.ExtensionData.Extension.ChildNodes | Select-Object name, state
    $GPOUserNodes1 = $xml1.GPO.User.ExtensionData.Extension.ChildNodes | Select-Object name, state
    $GPOUserNodes2 = $xml2.GPO.User.ExtensionData.Extension.ChildNodes | Select-Object name, state

    if ($computer){
        Try {
            Write-Host "Comparing Computer GPO's $($GpoReport[0]) with $($GpoReport[1]) `r`n"
            Compare-Object -ReferenceObject $GPOComputerNodes1 -DifferenceObject $GPOComputerNodes2 -IncludeEqual -Property name
        }

        Catch [System.Exception] {
            If ($GPOComputerNodes1) {
                Write-Host "Computer GPO $($GpoReport[0]) settings `r`f"
                Write-Host $GPOComputerNodes1
            }
            else {
                Write-Host "Computer GPO $($GpoReport[0]) not set" -ForegroundColor Yellow
                Write-Host $GPOComputerNodes2
            }

        If ($GPOComputerNodes2) {
                Write-Host "Computer GPO $($GpoReport[1]) settings `r`f"
            }
        else {
                Write-Host "Computer GPO $($GpoReport[1]) not set" -ForegroundColor Yellow
            }
        }
    }

if ($user){
    Try {
        Write-Host "Comparing Computer GPO's $($GpoReport[0]) with $($GpoReport[1]) `r`n"
        Compare-Object -ReferenceObject $GPOComputerNodes1 -DifferenceObject $GPOComputerNodes2 -IncludeEqual -Property name
        }

    Catch [System.Exception] {
        If ($GPOUserNodes1) {
            Write-Host "User GPO $($GpoReport[0]) settings `r`f"
            Write-Host $GPOUserNodes1
            }
        else {
            Write-Host "User GPO $($GpoReport[0]) not set" -ForegroundColor Yellow
            }

        If ($GPOUserNodes2) {
            Write-Host "User GPO $($GpoReport[1]) settings `r`f"
            Write-Host $GPOUserNodes2
            }
        else {
            Write-Host "User GPO $($GpoReport[1]) not set" -ForegroundColor Yellow
            }
        }
    }
}

# Main script
If (-not ($user -or $computer)) {Write-Host "Please specify either -user or -computer when running this script." -ForegroundColor Yellow; exit}

Write-Verbose "Importing Module Group Policy"
Import-Module GroupPolicy

$GPOReport = GPOReport -GPONames $GPONames.split(",") -DC $DC -Domain $Domain -Folder $Folder
GPOCompare -GPOReport $GPOReport -User $User -Computer $Computer

Exit