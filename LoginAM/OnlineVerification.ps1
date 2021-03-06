<#
 .SYNOPSIS
        Online Verification Script.
 .DESCRIPTION
        Online Verification Script that runs after the computer has completed it's LoginAM maintenance reboot.
        This script check several Citrix services on a english server os machine with installed Citrix VDA.
 .NOTES
        Author        : Thomas Krampe | t.krampe@loginconsultants.de
        Version       : 1.0
        Creation date : 26.10.2016 | v0.1 | Initial script
        Last change   : 02.03.2017 | v1.0 | Add additional Citrix Service checks
#>

# Prepare
$Return = $true
Import-Module AMClient
Write-AMInfo "Starting Verification."

try
{
    # <----- Place your additional code for more checks within this 'try' block ----->
    
    # Check the main VDA broker service
    $BrokerOnline = Get-Service -Name "BrokerAgent" 
    If ($BrokerOnline.Status -eq "Running") {
        Write-AMInfo "$($BrokerOnline.DisplayName) ist running"
        
        # Check the other services (only if Broker Service is running)
        $CitrixServices = Get-Service -Name Citrix*
        
        foreach ($CitrixService in $CitrixServices) {
            If ($CitrixService.Status -eq "Running") {
                Write-AMInfo "$($CitrixService.DisplayName) is running."
                }
            Else { 
                Write-AMInfo "$($CitrixService.DisplayName) isn't running."
                
                # If an additional service is in stopped state, we try to start the service first.
                try {
                    Write-AMInfo "Try to start $($CitrixService.DisplayName)."
                    Start-Service -DisplayName $($CitrixService.DisplayName)
                    Start-Sleep -Seconds 30
                    $SvcStarted = Get-Service -DisplayName $($CitrixService.DisplayName)
                    If ($SvcStarted.Status -eq "Running") {
                        Write-AMInfo "Service $($CitrixService.DisplayName) succesful started."
                    }
                    Else {
                        Write-AMInfo "Could not start $($CitrixService.DisplayName)."
                        $Return = $false
                        Break 
                    }
                }
                    catch {
                    $Reason = $_
                    Write-AMInfo "Service start failed. Error message: `'$Reason`'" 
                    $Return = $false
                }
            }
        }
    }
    Else {
        Write-AMInfo "$($BrokerOnline.DisplayName) isn't running."
        $Return = $false
        }
    
}

catch
{
    $Reason = $_
    $Return = $false
    Write-AMInfo "Something went wrong. Error message: `'$Reason`'"
}

switch ($Return)
{
    $false 
    {
        # <----- Place your additional code here (only runs in case of an error)----->
        Write-AMError "Verification script failed."

    }
    $true 
    {
        # <----- Place your additional code here (runs if no errors have occured)----->
        Write-AMInfo "Verification script succesful completed."
    }
}

Return $Return