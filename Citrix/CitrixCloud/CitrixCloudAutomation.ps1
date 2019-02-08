<# 
    .SYNOPSIS        
        CitrixCloudAutomation.ps1 

    .DESCRIPTION        
        Lightweight Script for creating deployments in Citrix Cloud        
    
    .PARAMETER xxx
        xxx

    .LINK        
        https://github.com/thomaskrampe/PowerShell/tree/master/Citrix/CitrixCloud 
    
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

        CREDITS
        -------
        Thanks to Aaron Parker <https://stealthpuppy.com> for the initial on-premise script.

#>
param(
    [Parameter(Mandatory=$true)][String]$DeploymentName


)

# -------------------------------------------------------------------------------------------------
# Infrastructure variables
# -------------------------------------------------------------------------------------------------
# Citrix Cloud infrastructure variables
$CCxdControllers = 'cloudcon01.myctxcloud.local'
$CCcustomerID  = 'ThomasKrampe'
$CCsecureClientFile = 'C:\tmp\CloudPoSH.csv'

# Azure connection and storage resources
# These need to be configured in Studio prior to running this script
# This script is hypervisor and management agnostic - just point to the right infrastructure
$AZHostingUnit = "AzureWE" 
$AZhostResource = "Visual Studio Premium with MSDN" 
$AZVMSize = "Standard_B2ms"
$AZRegion = "WestEurope"

# Machine catalog properties
$CCmachineCatalogName = $DeploymentName + "-MC"
$CCdomain = "myctxcloud.local"
$CCorgUnit = "OU=SessionHosts,OU=Citrix,DC=myctxcloud,DC=local"
$CCnamingScheme = $DeploymentName + "-MCS-##" # AD machine account naming conventions
$CCnamingSchemeType = "Numeric" # Possible values: Alphabetic, Numeric
$CCallocType = "Random" # Possible values: Static, Random
$CCpersistChanges = "OnLocal" # Possible values: OnLocal, Discard, OnPvD
$CCprovType = "MCS" # Possible values: Manual, MCS, PVS
$CCsessionSupport = "MultiSession" # Possible values: SingleSession, MultiSession
$CCmasterVMName = "cloudmaster*"
$CCmasterRG = "CitrixCloudRG"
$CCmachineCount = 1

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
                Create a machine catalog in Citrix Cloud
            .DESCRIPTION
                Create a machine catolog in Citrix Cloud   
            .PARAMETER xxx
                
            .EXAMPLE
            
        #>
        Param( 
            [Parameter(Mandatory=$true)][String]$MachineCatalogName,
            [Parameter(Mandatory=$true)][ValidateSet("Static","Random", "Permanent",IgnoreCase = $True)][String]$AllocType,
            [Parameter(Mandatory=$true)][ValidateSet("OnLocal","Discard","OnPvD",IgnoreCase = $True)][String]$PersistChanges,
            [Parameter(Mandatory=$true)][ValidateSet("Manual","MCS","PVS",IgnoreCase = $True)][String]$ProvType,
            [Parameter(Mandatory=$true)][ValidateSet("SingleSession","MultiSession",IgnoreCase = $True)][String]$SessionSupport,
            [Parameter(Mandatory=$true)][String]$Domain,
            [Parameter(Mandatory=$true)][String]$NamingScheme,
            [Parameter(Mandatory=$true)][ValidateSet("Alphabetic","Numeric",IgnoreCase = $True)][String]$NamingSchemeType,
            [Parameter(Mandatory=$true)][String]$OrgUnit,
            [Parameter(Mandatory=$true)][String]$MasterVMName,
            [Parameter(Mandatory=$true)][String]$AZHostingUnit,
            [Parameter(Mandatory=$true)][String]$AZVmSize,
            [Parameter(Mandatory=$true)][String]$MasterRG,
            [Parameter(Mandatory=$true)][String]$TargetRG,
            [Parameter(Mandatory=$true)][String]$XdControllers,
            [Parameter(Mandatory=$true)][Int]$MachineCount

        )

        begin {
        }

        process {
            # Get information from Citrix Cloud hosting environment 
            # TK_WriteLog "I" "Gathering connection informations from Citrix Cloud infrastructure." $LogFile
            # $hostingUnit = Get-ChildItem "XDHyp:\HostingUnits" | Where-Object { $_.PSChildName -like $AZstorageResource } | Select-Object PSChildName, PsPath
            # $hostConnection = Get-ChildItem "XDHyp:\Connections" | Where-Object { $_.PSChildName -like $hostResource }
            # $brokerHypConnection = Get-BrokerHypervisorConnection -HypHypervisorConnectionUid $hostConnection.HypervisorConnectionUid
            # $brokerServiceGroup = Get-ConfigServiceGroup -ServiceType 'Broker' -MaxRecordCount 2147483647

            # Create a empty Machine Catalog 
            TK_WriteLog "I" "Creating machine catalog. Name: $MachineCatalogName; Description: $MachineCatalogName; Allocation: $AllocType" $LogFile
            $brokerCatalog = New-BrokerCatalog -AllocationType $AllocType -Description $MachineCatalogName -Name $MachineCatalogName -PersistUserChanges $PersistChanges -ProvisioningType $ProvType -SessionSupport $SessionSupport
            
            # Create a identity pool to store AD machine accounts
            TK_WriteLog "I" "Creating a new identity pool for machine accounts." $LogFile
            $identPool = New-AcctIdentityPool -Domain $Domain -IdentityPoolName $MachineCatalogName -NamingScheme $NamingScheme -NamingSchemeType $NamingSchemeType -OU $OrgUnit

            # Update metadata key-value pairs for the catalog.
            TK_WriteLog "I" "Retrieving the newly created machine catalog." $LogFile
            $catalogUid = Get-BrokerCatalog | Where-Object { $_.Name -eq $MachineCatalogName } | Select-Object Uid
            $guid = [guid]::NewGuid()
            TK_WriteLog "I" "Updating metadata key-value pairs for the catalog." $LogFile
            Set-BrokerCatalogMetadata -CatalogId $catalogUid.Uid -Name 'Citrix_DesktopStudio_IdentityPoolUid' -Value $guid

            # Check to see whether a provisioning scheme is already available
            TK_WriteLog "I" "Check if the provisioning scheme name is not in use." $LogFile
            If (Test-ProvSchemeNameAvailable -ProvisioningSchemeName @($MachineCatalogName)) {
                TK_WriteLog "S"  "Provisioning scheme name is available." $LogFile

                # Get the master VM image from the same storage resource we're going to deploy to. Could pull this from another storage resource available to the host
                TK_WriteLog "I" "Getting the master image details for the new catalog: $MasterVMName" $LogFile
                $VM = Get-ChildItem "XDHyp:\HostingUnits\$AZHostingUnit\vm.folder" | Where-Object { $_.ObjectType -eq "VM" -and $_.PSChildName -like $MasterVMName }
                # Get the snapshot details. This code will assume a single snapshot exists - could add additional checking to grab last snapshot or check for no snapshots.
                $VMDetails = Get-ChildItem $VM.FullPath
                $ServiceOffering = Get-ChildItem "XDHyp:\HostingUnits\$AZHostingUnit\serviceoffering.folder" | Where-Object { $_.Name -like $AZVMSize }
  
                # Create a new provisioning scheme - the configuration of VMs to deploy. This will copy the master image to the target datastore.
                TK_WriteLog "I" "Creating new provisioning scheme using." $LogFile
                # Provision VMs based on the selected Azure resoucre.
                $MasterImageVM = Get-ChildItem "XDHyp:\HostingUnits\$AZHostingUnit\image.folder\$MasterRG.resourcegroup" | Where-Object { $_.ObjectTypeName -eq "manageddisk" -and $_.FullName -like $MasterVMName }
                $MasterImageVMDiskPath = $MasterImageVM.FullPath
                $ServiceOffering = Get-ChildItem "XDHyp:\HostingUnits\$AZHostingUnit\serviceoffering.folder" | Where-Object { $_.Name -like $AZVMSize }
                $ServiceOfferingPath = $ServiceOffering.FullPath
                $MasterImageNetwork = Get-ChildItem "XDHyp:\HostingUnits\$AZHostingUnit\virtualprivatecloud.folder\$MasterRG.resourcegroup\$MasterRG-vnet.virtualprivatecloud"
                $MasterImageNetworkPath = $MasterImageNetwork.FullPath
                $provTaskId = New-ProvScheme -ProvisioningSchemeName $MachineCatalogName -HostingUnitName $AZHostingUnit -MasterImageVM $MasterImageVMDiskPath -CleanOnBoot -IdentityPoolName $MachineCatalogName -CustomProperties "<CustomProperties xmlns=`"http://schemas.citrix.com/2014/xd/machinecreation`" xmlns:xsi=`"http://www.w3.org/2001/XMLSchema-instance`"><Property xsi:type=`"StringProperty`" Name=`"UseManagedDisks`" Value=`"true`" /><Property xsi:type=`"StringProperty`" Name=`"StorageAccountType`" Value=`"Premium_LRS`" /><Property xsi:type=`"StringProperty`" Name=`"LicenseType`" Value=`"Windows_Server`" /><Property xsi:type=`"StringProperty`" Name=`"ResourceGroups`" Value=`"$TargetRG`" /></CustomProperties>" -InitialBatchSizeHint 1 -NetworkMapping @{"0"=$MasterImageNetworkPath} -RunAsynchronously -Scope @() -SecurityGroup @() -ServiceOffering $ServiceOfferingPath
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
                    $ProvScheme = Get-ProvScheme | Where-Object { $_.ProvisioningSchemeName -eq $MachineCatalogName }
                    Set-BrokerCatalog -Name $provScheme.ProvisioningSchemeName -ProvisioningSchemeId $provScheme.ProvisioningSchemeUid

                    # Associate a specific set of controllers to the provisioning scheme. This steps appears to be optional.
                    TK_WriteLog "I" "Associating controllers to the provisioning scheme." $LogFile
                    Add-ProvSchemeControllerAddress -ControllerAddress @($XdControllers) -ProvisioningSchemeName $provScheme.ProvisioningSchemeName

                    # Provisiong the actual machines and map them to AD accounts, track the progress while this is happening
                    TK_WriteLog "I" "Creating the machine accounts in AD." $LogFile
                    $adAccounts = New-AcctADAccount -Count $MachineCount -IdentityPoolUid $identPool.IdentityPoolUid
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
                    $provVMs = Get-ProvVM -ProvisioningSchemeUid $provScheme.ProvisioningSchemeUid
                    TK_WriteLog "I" "Assigning the virtual machines to the new machine catalog." $LogFile
                    ForEach ( $provVM in $provVMs ) {
                        TK_WriteLog "I" "Locking VM $provVM.ADAccountName" $LogFile
                        Lock-ProvVM -ProvisioningSchemeName $ProvScheme.ProvisioningSchemeName -Tag 'Brokered' -VMID @($provVM.VMId)
                        TK_WriteLog "I" "Adding VM $provVM.ADAccountName" $LogFile
                        New-BrokerMachine -CatalogUid $catalogUid.Uid -MachineName $provVM.ADAccountName
                    }
                    TK_WriteLog "S" "Machine catalog creation complete succesful." $LogFile

                } Else {
                    # If provisioning task fails, provide error
                    # Check that the hypervisor management and storage resources do no have errors. Run 'Test Connection', 'Test Resources' in Citrix Studio
                    TK_WriteLog "E" "Provisioning task failed with error: [$provTask.TaskState] $provTask.TerminatingError" $LogFile
                    Write-Error "Provisioning task failed with error: [$provTask.TaskState] $provTask.TerminatingError"
                }
            }
            
        }

        end {
        }

    }

function TK_CreateDeliveryGroup {
        begin {
        }

        process {
        }

        end {
        }

    }

function TK_CreateAzRG {

    Param( 
        [Parameter(Mandatory=$true)][String]$AzResourceGroup,
        [Parameter(Mandatory=$true)][String]$AzRegion
        )
    
    begin {
        }
    
    process {
        # -------------------------------------------------------------------------------------------------
        # Prepare Variables
        # -------------------------------------------------------------------------------------------------
        $AzRGguid = [guid]::NewGuid()
        $CCTargetRG = $AzResourceGroup + "-xd-" + $AzRGguid
            
        TK_WriteLog "I" "Creating Azure Resource Group $CCTargetRG." $LogFile
        New-AzResourceGroup -Name $CCTargetRG -location $AzRegion -force
        
        Return $CCTargetRG
        }
    
        end {
        }
    }
    
#region Import Modules
# -------------------------------------------------------------------------------------------------
# Load the Citrix PowerShell modules
# -------------------------------------------------------------------------------------------------
TK_WriteLog "I" "Loading Citrix Remote Powershell Snapin." $LogFile
Add-PSSnapin Citrix*

TK_WriteLog "I" "Citrix Cloud Authentication." $LogFile
if (Test-Path $CCSecureClientFile) { 
    TK_WriteLog "S" "Create authentication profile with Customer ID and Token information." $LogFile
    Set-XDCredentials -ProfileType CloudAPI -CustomerId $CCcustomerID -SecureClientFile $CCSecureClientFile -StoreAs default 
    Get-XDAuthentication -ProfileName default
    }
    else {
        TK_WriteLog "E" "File not found: Authentication with secure client file failed." $LogFile
        TK_WriteLog "I" "Open authentication dialog." $LogFile
        Get-XdAuthentication 
    }

# -------------------------------------------------------------------------------------------------
# Load the Azure PowerShell modules
# -------------------------------------------------------------------------------------------------
if (!(Get-Module "Az")) {
    TK_WriteLog "I" "Loading Azure Powershell Module Az." $LogFile
    Import-Module AZ
    } 

#endregion

# -------------------------------------------------------------------------------------------------
# Main part - Creating Deployment
# -------------------------------------------------------------------------------------------------
$CCTargetRG = TK_CreateAzRG -AzResourceGroup $MachineCatalogName -AzRegion $AZRegion
$CCTargetRG = $CCTargetRG.Split(" ") | Select-Object -Last 1

TK_CreateMachineCatalog -MachineCatalogName $CCmachineCatalogName -AllocType $CCallocType -PersistChanges $CCpersistChanges -ProvType $CCprovType -SessionSupport $CCsessionSupport -Domain $CCdomain -NamingScheme $CCnamingScheme -NamingSchemeType $CCnamingSchemeType -OrgUnit $CCorgUnit -MasterVMName $CCmasterVMName -AZHostingUnit $AZHostingUnit -AZVmSize $AZVMSize -MasterRG $CCmasterRG -TargetRG $CCTargetRG -XdControllers $CCxdControllers -MachineCount $CCmachineCount
