<#
.SYNOPSIS
    Create additional Stores on Storefront Server

.DESCRIPTION
    Create additional Stores on Storefront Server including NS Gateway, Authentication and PNAgent.

.EXAMPLE
    This script should be used in LoginAM installation only and is build for the customer SID Kamenz.
    More informations about LoginAM https://loginvsi.com/products/login-am 

.LINK
    http://www.loginconsultants.de  
         
.NOTES
    Author        : Thomas Krampe | t.krampe@loginconsultants.de
    Company       : Login Consultants Germany GmbH, Karlsruhe
    Version       : 1.0
    Creation date : 27.02.2018 | v0.1 | Initial script
                  : 07.03.2018 | v1.0 | Add PNAgent configuration
                  : 08.03.2018 | v2.0 | Add "Script enabled" loop
    Last change   : 23.03.2018 | v3.0 | Update the NS Gateway CMDlets

    NOTICE
    THIS SCRIPT IS PROVIDED “AS IS” WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING 
    ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON-INFRINGEMENT. 
    LOGIN CONSULTANTS, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS OR OMISSIONS CONTAINED 
    HEREIN, NOR FOR DIRECT, INCIDENTAL, CONSEQUENTIAL OR ANY OTHER DAMAGES RESULTING FROM THE 
    FURNISHING, PERFORMANCE, OR USE OF THIS SCRIPT, EVEN IF THOMAS KRAMPE HAS BEEN ADVISED OF THE 
    POSSIBILITY OF SUCH DAMAGES IN ADVANCE.
#>

# Define global error handling
$global:ErrorActionPreference = "Stop"
if($verbose){ $global:VerbosePreference = "Continue" }

# Prepare Global Variables (Attention I use LoginAM environment variables here)
$EnableStores = $env:Enable_Stores
$SFStores = $env:SF_Store_List
$AdditionalStores = $SFStores.Split(",") # Build an array from comma separated list
$SiteID = 1  # Should be normally 1
$DDCGroup = $env:xd_sf_servers
$DDCs = $DDCGroup.Split(",") # Build an array from comma separated list
$DDC = $DDCs[0] # Select the first DDC from the list
$FarmType = $env:xd_sf_type
$SSLRelayPort = $env:xd_sf_sslport
$XMLPort = $env:xd_sf_port
$TransportType = $env:xd_sf_transporttype
$CreateGateway = $env:Create_NS_Gateway
$GatewayFQDN = $env:NS_Gateway_FQDN
$GatewayFriendlyName = $env:NS_Gateway_Name
$STAURL = "http://$DDC"
$GWSubnetIP = $env:NS_Gateway_IP
$EnablePNAgent = $env:Create_PNAgent

# A little bit housekeeping
if ($CreateGateway -eq "false") {$CreateGateway = $false}
if ($CreateGateway -eq "true") {$CreateGateway = $true}
if ($EnablePNAgent -eq "false") {$EnablePNAgent = $false}
if ($EnablePNAgent -eq "true") {$EnablePNAgent = $true}

if ($EnableStores -eq "true") {

    # Import StoreFront modules. 
     Write-Host "Importing Storefront Powershell Modules." -foregroundcolor green
     try {
            & "C:\Program Files\Citrix\Receiver StoreFront\Scripts\ImportModules.ps1"
     } catch {
            Write-Host "An error occurred trying to import the Storefront PowerShell modules - (error: $($Error[0]))" -foregroundcolor red
            Exit 1
     }
    

    ###############################################################################
    # Create NetScaler Gateway configuration
    ###############################################################################
    Write-Host "Starting NetScaler Gateway creation." -foregroundcolor yellow
    
    $GatewayExist = Get-STFRoamingGateway

    if ($CreateGateway) {
        if ( !($GatewayExist)) {
            try {
                Write-Host "Create NetScaler Gateway $GatewayFriendlyName as default" -foregroundcolor yellow
                Add-STFRoamingGateway -Name $GatewayFriendlyName -LogonType Domain -Version Version10_0_69_4 -GatewayUrl $GatewayFQDN -CallbackUrl $GatewayFQDN -StasUseLoadBalancing:$false -SessionReliability:$false -RequestTicketTwoSTAs:$false -SecureTicketAuthorityUrls $STAURL -SubnetIPAddress $GWSubnetIP

            } catch {
                Write-Host "An error occurred trying to create the NetScaler Gateway $GatewayFriendlyName - (error: $($Error[0]))" -foregroundcolor red
                Exit 1
           }
        } else {
           write-host "Gateway creation enabled, but Gateway $GatewayFriendlyName already exists. Use existing." -ForegroundColor Yellow
       }    
    } else {
        Write-Host "Creation of NetScaler Gateway not enabled." -foregroundcolor green
    }   

    ###############################################################################
    # Create Storefront Stores
    ###############################################################################

    foreach ($AdditionalStore in $AdditionalStores) {

        # Variables
        $FarmName = $AdditionalStore
        $StoreVirtualPath = "/Citrix/$FarmName"
        $AuthVirtualPath = "$($StoreVirtualPath.TrimEnd('/'))Auth"
        $ReceiverForWeb = $FarmName + "Web"
        $receiverVirtualPath = "/Citrix/$ReceiverForWeb"
    
        ###############################################################################
        # Determine if the authentication service at the specified virtual path exists
        ###############################################################################
    
        $authentication = Get-STFAuthenticationService -siteID $SiteId -VirtualPath $AuthVirtualPath
            if ( !($authentication) ) {
                # Add an authentication service using the IIS path of the store appended with Auth
            
                try {
                    $authentication = Add-STFAuthenticationService -siteID $SiteId -VirtualPath $AuthVirtualPath
                
                } catch {
                    Write-Host "An error occurred trying to create the authentication service at the path $AuthVirtualPath in the IIS site $SiteId (error: $($Error[0]))" -foregroundcolor red
                    Exit 1
                }
            } else {
                Write-Host "An authentication service already exists at $AuthVirtualPath in the IIS site $SiteID and will be used" -foregroundcolor green
            }

        ###############################################################################
        # Create store and farm
        ###############################################################################
        $Store = Get-STFStoreService -siteID $SiteId -VirtualPath $StoreVirtualPath
    
        if ( !($Store) ) {
    
            # Add a store that uses the new authentication service configured to publish resources from the supplied servers
            try {
                $Store = Add-STFStoreService -FriendlyName $farmName -siteID $SiteId -VirtualPath $StoreVirtualPath -AuthenticationService $authentication -FarmName $FarmName -FarmType $FarmType -Servers $DDC -SSLRelayPort $SSLRelayPort -LoadBalance $false -Port $XMLPort -TransportType $TransportType
            } 
            catch {
                Write-Host "An error occurred trying to create the store service with the following configuration (error: $($Error[0])):" -foregroundcolor red
                Exit 1
            }
        } else {
            # During the creation of the store at least one farm is defined, so there must at the very least be one farm present in the store
            Write-Host "A store service called $($Store.Name) already exists at the path $StoreVirtualPath in the IIS site $SiteId" -foregroundcolor yellow
            Write-Host "Retrieve the available farms in the store $($Store.Name)." -foregroundcolor yellow
            $ExistingFarms = (Get-STFStoreFarmConfiguration $Store).Farms.FarmName
            $TotalFarmsFound = $ExistingFarms.Count
            Write-Host "Total farms found: $TotalFarmsFound" -foregroundcolor yellow
            Foreach ( $Farm in $ExistingFarms ) {
                Write-Host "Farm name: $Farm" -foregroundcolor yellow    
            }
 
            # Loop through each farm, check if the farm name is the same as the one defined in the variable $FarmName. If not, create/add a new farm to the store
            $ExistingFarmFound = $False
            Write-Host "Check if the farm $FarmName already exists" -foregroundcolor yellow
            Foreach ( $Farm in $ExistingFarms ) {
                if ( $Farm -eq $FarmName ) {
                    $ExistingFarmFound = $True
                    # The farm exists. Nothing to do. This script will now end.
                    Write-Host "The farm $FarmName exists" -foregroundcolor yellow
                }
            }
 
            # Create a new farm in case existing farms were found, but none matching the farm name defined in the variable $HostbaseUrl
            If ( $ExistingFarmFound -eq $False ) {
                Write-Host "The farm $FarmName does not exist" -foregroundcolor yellow
                Write-Host "I" "Create the new farm $FarmName" -foregroundcolor yellow
                # Create the new farm
                try {
                    Add-STFStoreFarm -StoreService $store -FarmName $FarmName -FarmType $FarmType -Servers $FarmServers -SSLRelayPort $SSLRelayPort -LoadBalance $LoadBalanceServers -Port $XMLPort -TransportType $TransportType
                    Write-Host "The farm $FarmName with the following configuration was created successfully." -foregroundcolor yellow
                    
                } catch {
                    Write-Host "An error occurred trying to create the farm $FarmName with the following configuration (error: $($Error[0])):" -foregroundcolor red
                    Exit 1
                }
            }
        }
    
        ##############################################################################################
        # Determine if the Receiver for Web service at the specified virtual path and IIS site exists
        ##############################################################################################
        Write-Host "Determine if the Receiver for Web service at the path $receiverVirtualPath in the IIS site $SiteId exists" -foregroundcolor yellow
        try {
            $receiver = Get-STFWebReceiverService -siteID $SiteID -VirtualPath $receiverVirtualPath
        } catch {
            Write-Host "An error occurred trying to determine if the Receiver for Web service at the path $receiverVirtualPath in the IIS site $SiteId exists (error: $($Error[0]))" -foregroundcolor red
            Exit 1
        }

        # Create the receiver server if it does not exist
        if ( !($receiver) ) {
            Write-Host "Add the Receiver for Web service at the path $receiverVirtualPath in the IIS site $SiteId" -foregroundcolor yellow
            # Add a Receiver for Web site so users can access the applications and desktops in the published in the Store
            try {
                $receiver = Add-STFWebReceiverService -siteID $SiteId -VirtualPath $receiverVirtualPath -StoreService $Store
                Write-Host "The Receiver for Web service at the path $receiverVirtualPath in the IIS site $SiteId was created successfully" -foregroundcolor yellow
            } catch {
                Write-Host "An error occurred trying to create the Receiver for Web service at the path $receiverVirtualPath in the IIS site $SiteId (error: $($Error[0]))" -foregroundcolor red
                Exit 1
            }
        } else {
            Write-Host "A Receiver for Web service already exists at the path $receiverVirtualPath in the IIS site $SiteId" -foregroundcolor green
        }


        ##############################################################################################
        # Determine if the PNAgent service at the specified virtual path and IIS site exists
        ##############################################################################################
        $StoreName = $Store.Name
        Write-Host "Determine if the PNAgent on the store '$StoreName' in the IIS site $SiteId is enabled" -foregroundcolor yellow
        
        try {
            $storePnaSettings = Get-STFStorePna -StoreService $Store
        } catch {
            Write-Host "An error occurred trying to determine if the PNAgent on the store '$StoreName' is enabled" -foregroundcolor red
            Exit 1
        }

        # Enable the PNAgent if required
        if ( $EnablePNAgent -eq $True ) {
            if ( !($storePnaSettings.PnaEnabled) ) {
                Write-Host "The PNAgent is not enabled on the store '$StoreName'" -foregroundcolor yellow
                Write-Host "Enable the PNAgent on the store '$StoreName'" -foregroundcolor yellow

                # Enable the PNAgent
                try {
                        Enable-STFStorePna -StoreService $store -AllowUserPasswordChange -LogonMethod "Prompt"
                        Write-Host "The PNAgent was enabled successfully on the store '$StoreName'" -foregroundcolor yellow
                        Write-Host "   -Allow user change password: yes" -foregroundcolor yellow
                        Write-Host "   -Default PNAgent service: no" -foregroundcolor yellow
                    } catch {
                        Write-Host "An error occurred trying to enable the PNAgent on the store '$StoreName' (error: $($Error[0]))" -foregroundcolor red
                        Exit 1
                    }
                     
            } else {
                Write-Host "The PNAgent is already enabled on the store '$StoreName' in the IIS site $SiteId" -foregroundcolor yellow
            }
        } else {
            Write-Host "The PNAgent should not be enabled on the store '$StoreName' in the IIS site $SiteId" -foregroundcolor green
        }
       
        ##############################################################################################
        # Configure NetScaler Gateway for this store
        ##############################################################################################
    
        $Gateway = Get-STFRoamingGateway -Name $GatewayFriendlyName
        
        if ($gateway){
    
            try {
                
                Write-Host "Set NetScaler Gateway $GatewayFriendlyName for Store $FarmName" -foregroundcolor yellow
                
                $Store = Get-STFStoreService -siteID 1 -VirtualPath $StoreVirtualPath
                Register-STFStoreGateway -Gateway $Gateway -StoreService $Store -DefaultGateway:$False -UseFullVpn:$False

            } catch {
                Write-Host "An error occurred trying to configure NetScaler Gateway $GatewayFriendlyName for store $FarmName (error: $($Error[0]))" -foregroundcolor red
                Exit 1
            }
        } else {
            Write-Host "No global gateway configured." -foregroundcolor green
        }
    }
} else {
    write-host "Creating additional stores action item not enabled in collection." -foregroundcolor yellow
}

Exit 0