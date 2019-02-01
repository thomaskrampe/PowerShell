<# 
    .SYNOPSIS        
        CitrixCloudAutomation.ps1 

    .DESCRIPTION        
        Lightweight Script for         
        - Ex- and Importing GPO's for e.g. GPO migration        
        - Creating version reports as CSV        
        - Compare GPO settings        
        - CleanUp Logfiles are written to Logfiles are written to C:\_Logs by default 
    
    .PARAMETER xxx
        xxx

    .LINK        
        https://github.com/thomaskrampe/PowerShell/ 
    
    .NOTES       
        Author        : Thomas Krampe | thomas.krampe@myctx.net        
        Version       : 0.1            
        Creation date : 25.01.2019 | v0.1 | Initial script         
                      : xx.xx.2019 | v1.0 | 
        Last change   : xx.xx.2019 | v1.1 | 
        
        IMPORTANT NOTICE 
        ---------------- 
        THIS SCRIPT IS PROVIDED "AS IS" WITHOUT WARANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING        
        ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT.        
        THOMAS KRAMPE, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS OR OMISSIONS CONTAINED         
        HEREIN, NOT FOR DIRECT, INCIDENTIAL, CONSEQUENTIAL OR ANY OTHER DAMAGES RESULTING FROM FURNISHING,        
        PERFORMANCE, OR USE OF THIS SCRIPT, EVEN IF THOMAS KRAMPE HAS BEEN ADVISED OF THE POSSIBILITY        
        OF SUCH DAMAGES IN ADVANCE.
#>

# -------------------------------------------------------------------------------------------------
# Infrastructure variables
# -------------------------------------------------------------------------------------------------
$xdControllers = 'cloudcon01.myctxcloud.local'
$CCcustomerID  = 'ThomasKrampe'
$CCSecureClientFile = 'C:\tmp\CloudPoSH.csv'

# Azure connection and storage resources
# These need to be configured in Studio prior to running this script
# This script is hypervisor and management agnostic - just point to the right infrastructure
$storageResource = "AzureWE" 
$hostResource = "Visual Studio Premium with MSDN" 

# Machine catalog properties
$machineCatalogName = "TEST02-MC"
$machineCatalogDesc = "TEST02-MC"
$domain = "myctxcloud.local"
$orgUnit = "OU=SessionHosts,OU=Citrix,DC=myctxcloud,DC=local"
$namingScheme = "TEST02-MCS-##" # AD machine account naming conventions
$namingSchemeType = "Numeric" # Possible values: Alphabetic, Numeric
$allocType = "Random" # Possible values: Static, Random
$persistChanges = "OnLocal" # Possible values: OnLocal, Discard, OnPvD
$provType = "MCS" # Possible values: Manual, MCS, PVS
$sessionSupport = "MultiSession" # Possible values: SingleSession, MultiSession
$masterImage ="WIN81*"
$vCPUs = 2
$VRAM = 2048

# -------------------------------------------------------------------------------------------------
# Global Error handling and verbose output
# -------------------------------------------------------------------------------------------------
$global:ErrorActionPreference = "Stop"
if($verbose){ $global:VerbosePreference = "Continue" }

# -------------------------------------------------------------------------------------------------
# Log handling
# -------------------------------------------------------------------------------------------------
$LogDir = "C:\_Logs"
$ScriptName = "CitrixCloudAutomation"
$DateTime = Get-Date -uformat "%Y-%m-%d_%H-%M"
$LogFileName = "$ScriptName"+"$DateTime.log"
$LogFile = Join-path $LogDir $LogFileName

# Create the log directory if it does not exist
if (!(Test-Path $LogDir)) { New-Item -Path $LogDir -ItemType directory | Out-Null }

# Create new log file (overwrite existing one)
New-Item $LogFile -ItemType "file" -force | Out-Null

# -------------------------------------------------------------------------------------------------
# FUNCTIONS (don't change anything below)
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

function TK_CreateMachineCatalog {
        <#
            .SYNOPSIS
                
            .DESCRIPTION
               
            .PARAMETER xxx
                
            .EXAMPLE
            
        #>
        Param( 
            [Parameter(Mandatory=$true, Position = 0)][ValidateSet("I","S","W","E","-",IgnoreCase = $True)][String]$InformationType,
            [Parameter(Mandatory=$true, Position = 1)][AllowEmptyString()][String]$Text,
            [Parameter(Mandatory=$true, Position = 2)][AllowEmptyString()][String]$LogFile
        )

        begin {
        }

        process {
            # Get information from Citrix Cloud hosting environment 
            TK_WriteLog "I" "Gathering connections from Citrix Cloud infrastructure." $LogFile
            # $hostingUnit = Get-ChildItem "XDHyp:\HostingUnits" | Where-Object { $_.PSChildName -like $storageResource } | Select-Object PSChildName, PsPath
            # $hostConnection = Get-ChildItem "XDHyp:\Connections" | Where-Object { $_.PSChildName -like $hostResource }
            # $brokerHypConnection = Get-BrokerHypervisorConnection -HypHypervisorConnectionUid $hostConnection.HypervisorConnectionUid
            # $brokerServiceGroup = Get-ConfigServiceGroup -ServiceType 'Broker' -MaxRecordCount 2147483647

            # Create a Machine Catalog. 
            TK_WriteLog "I" "Creating machine catalog. Name: $machineCatalogName; Description: $machineCatalogDesc; Allocation: $allocType" $LogFile
            $brokerCatalog = New-BrokerCatalog -AllocationType $allocType -Description $machineCatalogDesc -Name $machineCatalogName -PersistUserChanges $persistChanges -ProvisioningType $provType -SessionSupport $sessionSupport
            # The identity pool is used to store AD machine accounts
            TK_WriteLog "I" "Creating a new identity pool for machine accounts." $LogFile
            $identPool = New-AcctIdentityPool -Domain $domain -IdentityPoolName $machineCatalogName -NamingScheme $namingScheme -NamingSchemeType $namingSchemeType -OU $orgUnit

            # Creates/Updates metadata key-value pairs for the catalog (no idea why).
            TK_WriteLog "I" "Retrieving the newly created machine catalog." $LogFile
            $catalogUid = Get-BrokerCatalog | Where-Object { $_.Name -eq $machineCatalogName } | Select-Object Uid
            $guid = [guid]::NewGuid()
            TK_WriteLog "I" "Updating metadata key-value pairs for the catalog." $LogFile
            Set-BrokerCatalogMetadata -CatalogId $catalogUid.Uid -Name 'Citrix_DesktopStudio_IdentityPoolUid' -Value $guid

            # Check to see whether a provisioning scheme is already available
            TK_WriteLog "I" "Check if the provisioning scheme name is not in use." $LogFile
            If (Test-ProvSchemeNameAvailable -ProvisioningSchemeName @($machineCatalogName)) {
                TK_WriteLog "S"  "Provisioning scheme name is available." $LogFile

                # Get the master VM image from the same storage resource we're going to deploy to. Could pull this from another storage resource available to the host
                TK_WriteLog "I" "Getting the master image details for the new catalog: $masterImage" $LogFile
                $VM = Get-ChildItem "XDHyp:\HostingUnits\$storageResource" | Where-Object { $_.ObjectType -eq "VM" -and $_.PSChildName -like $masterImage }
                # Get the snapshot details. This code will assume a single snapshot exists - could add additional checking to grab last snapshot or check for no snapshots.
                $VMDetails = Get-ChildItem $VM.FullPath
  
                # Create a new provisioning scheme - the configuration of VMs to deploy. This will copy the master image to the target datastore.
                TK_WriteLog "I" "Creating new provisioning scheme using $VMDetails.FullPath" $LogFile
                # Provision VMs based on the selected snapshot.
                $provTaskId = New-ProvScheme -ProvisioningSchemeName $machineCatalogName -HostingUnitName $storageResource -MasterImageVM $VMDetails.FullPath -CleanOnBoot -IdentityPoolName $identPool.IdentityPoolName -VMCpuCount $vCPUs -VMMemoryMB $vRAM -RunAsynchronously
                $provTask = Get-ProvTask -TaskId $provTaskId

                # Track the progress of copying the master image
                TK_WriteLog "I" "Tracking progress of provisioning scheme creation task." $LogFile
                $totalPercent = 0
                While ( $provTask.Active -eq $True ) {
                    Try { $totalPercent = If ( $provTask.TaskProgress ) { $provTask.TaskProgress } Else {0} } Catch { }

                Write-Progress -Activity "Creating Provisioning Scheme (copying and composing master image):" -Status "$totalPercent% Complete:" -percentcomplete $totalPercent
                Start-Sleep 15
                $provTask = Get-ProvTask -TaskID $provTaskId
                }

                # If provisioning task fails, there's no point in continuing further.
                If ( $provTask.WorkflowStatus -eq "Completed" ) { 
                    # Apply the provisioning scheme to the machine catalog
                    TK_WriteLog "I" "Binding provisioning scheme to the new machine catalog" $LogFile
                    $provScheme = Get-ProvScheme | Where-Object { $_.ProvisioningSchemeName -eq $machineCatalogName }
                    Set-BrokerCatalog -Name $provScheme.ProvisioningSchemeName -ProvisioningSchemeId $provScheme.ProvisioningSchemeUid

                    # Associate a specific set of controllers to the provisioning scheme. This steps appears to be optional.
                    TK_WriteLog "I" "Associating controllers $xdControllers to the provisioning scheme." $LogFile
                    Add-ProvSchemeControllerAddress -ControllerAddress @($xdControllers) -ProvisioningSchemeName $provScheme.ProvisioningSchemeName

                    # Provisiong the actual machines and map them to AD accounts, track the progress while this is happening
                    TK_WriteLog "I" "Creating the machine accounts in AD." $LogFile
                    $adAccounts = New-AcctADAccount -Count 5 -IdentityPoolUid $identPool.IdentityPoolUid
                    TK_WriteLog "I" "Creating the virtual machines." $LogFile
                    $provTaskId = New-ProvVM -ADAccountName @($adAccounts.SuccessfulAccounts) -ProvisioningSchemeName $provScheme.ProvisioningSchemeName -RunAsynchronously
                    $provTask = Get-ProvTask -TaskId $provTaskId

                    TK_WriteLog "I" "Tracking progress of the machine creation task." $LogFile
                    $totalPercent = 0
                    While ( $provTask.Active -eq $True ) {
                        Try { $totalPercent = If ( $provTask.TaskProgress ) { $provTask.TaskProgress } Else {0} } Catch { }

                        Write-Progress -Activity "Creating Virtual Machines:" -Status "$totalPercent% Complete:" -percentcomplete $totalPercent
                        Start-Sleep 15
                        $ProvTask = Get-ProvTask -TaskID $provTaskId
                    }

                    # Assign the newly created virtual machines to the machine catalog
                    $provVMs = Get-ProvVM -AdminAddress $adminAddress -ProvisioningSchemeUid $provScheme.ProvisioningSchemeUid
                    TK_WriteLog "I" "Assigning the virtual machines to the new machine catalog." $LogFile
                    ForEach ( $provVM in $provVMs ) {
                        TK_WriteLog "I" "Locking VM $provVM.ADAccountName" $LogFile
                        Lock-ProvVM -ProvisioningSchemeName $provScheme.ProvisioningSchemeName -Tag 'Brokered' -VMID @($provVM.VMId)
                        TK_WriteLog "I" "Adding VM $provVM.ADAccountName" $LogFile
                        New-BrokerMachine -CatalogUid $catalogUid.Uid -MachineName $provVM.ADAccountName
                    }
                    TK_WriteLog "I" "Machine catalog creation complete." $LogFile

                } Else {
                    # If provisioning task fails, provide error
                    # Check that the hypervisor management and storage resources do no have errors. Run 'Test Connection', 'Test Resources' in Citrix Studio
                    Write-Error "Provisioning task failed with error: [$provTask.TaskState] $provTask.TerminatingError"
                }
            }
            
        }

        end {
        }

    }




# -------------------------------------------------------------------------------------------------
# Load the Citrix PowerShell modules
# -------------------------------------------------------------------------------------------------
TK_WriteLog "I" "Loading Citrix Remote Powershell Module." $LogFile
Add-PSSnapin Citrix*

TK_WriteLog "I" "Citrix Cloud Authentication." $LogFile
if (Test-Path $CCSecureClientFile) { 
    TK_WriteLog "I" "Create authentication profile with Customer ID $CCcustomerID and Token information from $CCSecureClientFile." $LogFile
    Set-XDCredentials -ProfileType CloudAPI -CustomerId $CCcustomerID -SecureClientFile $CCSecureClientFile -StoreAs default 
    Get-XDAuthentication -ProfileName default
    }
    else {
        TK_WriteLog "E" "File not found: Authentication with secure client file $CCSecureClientFile failed." $LogFile
        TK_WriteLog "I" "Open authentication dialog." $LogFile
        Get-XdAuthentication 
    }

# -------------------------------------------------------------------------------------------------
# Main part - Creating Machine Catalog
# -------------------------------------------------------------------------------------------------

TK_CreateMachineCatalog



