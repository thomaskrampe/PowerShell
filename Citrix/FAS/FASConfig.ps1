<#
 .SYNOPSIS
        FASConfig.ps1

 .DESCRIPTION
        Lightweight Script for Enable, Disable or Audit Storefront Stores for FAS
        
 .PARAMETER Mode
        Enable 
        Disable
        Audit
        
 .EXAMPLE
        
        FASConfig.ps1 -Mode Enable
        FASConfig.ps1 -Mode Disable 
        FASConfig.ps1 -Mode Audit
        
 .LINK
        https://github.com/thomaskrampe/PowerShell/blob/master/Citrix/FAS/FASConfig.ps1

 .NOTES
        Author        : Thomas Krampe | thomas.krampe@myctx.net
        Version       : 1.0
        Creation date : 12.09.2018 | v0.1 | Initial script
        Last change   : 14.09.2018 | v1.0 | Release to Github

        IMPORTANT NOTICE
        ----------------
        THIS SCRIPT IS PROVIDED "AS IS" WITHOUT WARANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
        ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT.
        THOMAS KRAMPE, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS OR OMISSIONS CONTAINED 
        HEREIN, NOT FOR DIRECT, INCIDENTIAL, CONSEQUENTIAL OR ANY OTHER DAMAGES RESULTING FROM FURNISHING,
        PERFORMANCE, OR USE OF THIS SCRIPT, EVEN IF THOMAS KRAMPE HAS BEEN ADVISED OF THE POSSIBILITY
        OF SUCH DAMAGES IN ADVANCE.

#>

# Script parameter        
Param(
    [Parameter(Mandatory=$True)][ValidateSet("Enable", "Disable", "Audit")][string]$Mode
)

# Define global Error handling
$global:ErrorActionPreference = "Stop"
if($verbose){ $global:VerbosePreference = "Continue" }

# -------------------------------------------------------------------------------------------------
# FUNCTIONS (don't change anything here)
# -------------------------------------------------------------------------------------------------

function TK_AuditFAS {
    begin {
    }

    process {
         $SFSTores = Get-STFStoreService
         Foreach ($SFStore in $SFSTores) {
            $StoreVirtualPath = $SFStore.VirtualPath
            $Store = Get-STFStoreService -VirtualPath $StoreVirtualPath
            $Auth = Get-STFAuthenticationService -StoreService $Store
    
            $FASAudit = Get-STFStoreLaunchOptions -StoreService $Store
            
            If ($FASAudit.VdaLogonDataProviderName -eq "FASLogonDataProvider") {
                Write-Host "FAS ist auf dem Store $($SFStore.VirtualPath) aktiviert." -ForegroundColor Green
                }
            else {
                Write-Host "FAS ist nicht auf dem Store $($SFStore.VirtualPath) aktiviert." -ForegroundColor Red
            }
        }   
    }

    end {
    }

}

function TK_EnableFAS {
    begin {
    }

    process {
        $SFSTores = Get-STFStoreService 
        Foreach ($SFStore in $SFSTores) {
            # Better Exclusion as a later improvement, for now just a simple if then
            If ( $SFStore.VirtualPath -eq "/Citrix/Store" -or $SFStore.VirtualPath -eq "/Citrix/Intern") {
            Write-Host "Store $($SFStore.VirtualPath) is excluded." -ForegroundColor Red
            } Else {
                Write-Host "Configuring $($SFStore.VirtualPath) for FAS authentication." -ForegroundColor Yellow
    
                $StoreVirtualPath = $SFStore.VirtualPath
                $Store = Get-STFStoreService -VirtualPath $StoreVirtualPath
                $Auth = Get-STFAuthenticationService -StoreService $Store
    
                Set-STFClaimsFactoryNames -AuthenticationService $Auth -ClaimsFactoryName "FASClaimsFactory"
                Set-STFStoreLaunchOptions -StoreService $Store -VdaLogonDataProvider "FASLogonDataProvider"
                Write-Host "All done with $StoreVirtualPath." -ForegroundColor Green
            }
        }       
    }

    end {
    }

}

function TK_DisableFAS {
    begin {
    }

    process {
        $SFSTores = Get-STFStoreService 
        Foreach ($SFStore in $SFSTores) {
            Write-Host "Configuring $($SFStore.VirtualPath) for standard authentication (Disable FAS)." -ForegroundColor Yellow
    
            $StoreVirtualPath = $SFStore.VirtualPath
            $Store = Get-STFStoreService -VirtualPath $StoreVirtualPath
            $Auth = Get-STFAuthenticationService -StoreService $Store
    
            Set-STFClaimsFactoryNames -AuthenticationService $Auth -ClaimsFactoryName "standardClaimsFactory"
            Set-STFStoreLaunchOptions -StoreService $Store -VdaLogonDataProvider ""
            Write-Host "FAS on Store $StoreVirtualPath disabled." -ForegroundColor Green
         }
    }       
    
    end {
    }

}

# -------------------------------------------------------------------------------------------------
# MAIN SECTION
# -------------------------------------------------------------------------------------------------

# Disable File Security
$env:SEE_MASK_NOZONECHECKS = 1

Clear-Host

Write-Host "Starting script in $mode mode.`n`r" -ForegroundColor Yellow

# Import PowerShell Module
Get-Module "Citrix.Storefront.*" -ListAvailable | Import-Module


switch ($Mode){
    "Enable" {TK_EnableFAS; break}
    "Disable" {TK_DisableFAS; break}
    "Audit" {TK_AuditFAS; break}
    
}


