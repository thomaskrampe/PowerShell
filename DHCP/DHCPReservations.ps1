<#
 .SYNOPSIS
        Export or Import DHCP reservations

 .DESCRIPTION
        Export or Import DHCP reservations

 .PARAMETER Mode
        Export or Import

 .PARAMETER DataPath
        Path to the file (eg. c:\temp)

 .EXAMPLE
        .\DHCPReservations.ps1 -Mode Export -DataPath "C:\temp" -Verbose
 
 .LINK
        https://github.com/thomaskrampe/Citrix-PowerShell-Scripts 
                 
 .NOTES
        Author        : Thomas Krampe | t.krampe@loginconsultants.de
        Version       : 1.0
        Creation date : 12.02.2018 | v0.1 | Initial script
        Last change   : 12.02.2018 | v1.0 | Release to GitHub

 .TODO
        Create Scope Part
        https://docs.microsoft.com/en-us/powershell/module/dhcpserver/add-dhcpserverv4scope?view=win10-ps
#>

Param (
    [Parameter(Mandatory=$true)] [string]$Mode,
    [Parameter(Mandatory=$true)] [string]$DataPath
)


# Export DHCP reservations to CSV file
function ExportDHCP {
    Param (
       [string]$DataPath 
    )
    write-Verbose "Creating output file $DataPath\$($env:COMPUTERNAME)-Reservations.csv"
    Get-DHCPServerV4Scope | ForEach {Get-DHCPServerv4Lease -ScopeID $_.ScopeID | where {$_.AddressState -like '*Reservation'}} | Select-Object ScopeId,IPAddress,HostName,ClientID | Export-Csv "$DataPath\$($env:COMPUTERNAME)-Reservations.csv" -NoTypeInformation
}


# Import DHCP reservations from CSV file
function ImportDHCP {
    Param (
       [string]$DataPath 
    )         
    if (Test-Path "$DataPath\$($env:COMPUTERNAME)-Reservations.csv" ) {
    $ResList = import-csv -Path "$DataPath\$($env:COMPUTERNAME)-Reservations.csv" -Delimiter "," 
    }
    Else {write-error "File not exists"; exit}
    try {
        foreach( $r in $reslist ) 
            { 
                if ( $r.ClientID -eq $null -Or $r.ClientID -eq "ClientID" ) { continue } 
                $DHCPScopeID = $r.ScopeId
                $DHCPMacAddress = $r.ClientID 
                $DHCPIPAddress = $r.IPAddress
                $DHCPHostname = $r.HostName
            
                Write-Verbose "Importing: $DHCPScopeID, $DHCPIPAddress, $DHCPHostname, $DHCPMacAddress"
                Add-DhcpServerv4Reservation -ScopeId $DHCPScopeID -IPAddress $DHCPIPAddress -Name $DHCPHostname -ClientId $DHCPMacAddress -Type Dhcp 
                }
         }
         catch {
                    $Reason = $_
                    Write-AMInfo "Service start failed. Error message: `'$Reason`'" 
                    } 
}


switch ($Mode) {
    Export {ExportDHCP -DataPath $DataPath}
    Import {ImportDHCP -DataPath $DataPath}
    default {throw "No Mode selected"}
    }


