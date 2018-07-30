<#
 .SYNOPSIS
    Deploys a template to Azure

 .DESCRIPTION
    Deploys an Azure Resource Manager template
#>

param (
    [Parameter(Mandatory)]
    #The subscription id where the template will be deployed.
    [string]$SubscriptionId,  

    [Parameter(Mandatory)]
    #The resource group where the template will be deployed. Can be the name of an existing or a new resource group.
    [string]$ResourceGroupName, 

    #Optional, a resource group location. If specified, will try to create a new resource group in this location. If not specified, assumes resource group is existing.
    [string]$ResourceGroupLocation, 

    #The deployment name.
    [Parameter(Mandatory)]
    [string]$DeploymentName,    

    #Path to the template file. Defaults to template.json.
    [string]$TemplateFilePath = "azuredeploy.json",  

    #Path to the parameters file. Defaults to parameters.json. If file is not found, will prompt for parameter values based on template.
    [string]$ParametersFilePath = "azuredeploy.parameters.json"
)

$ErrorActionPreference = "Stop"

# Login to Azure and select subscription
Write-Output "Logging in"
Login-AzureRmAccount
Write-Output "Selecting subscription '$SubscriptionId'"
Select-AzureRmSubscription -SubscriptionID $SubscriptionId

# Create or check for existing resource group
$resourceGroup = Get-AzureRmResourceGroup -Name $ResourceGroupName -ErrorAction SilentlyContinue
if ( -not $ResourceGroup ) {
    Write-Output "Could not find resource group '$ResourceGroupName' - will create it"
    if ( -not $ResourceGroupLocation ) {
        $ResourceGroupLocation = Read-Host -Prompt 'Enter location for resource group'
    }
    Write-Output "Creating resource group '$ResourceGroupName' in location '$ResourceGroupLocation'"
    New-AzureRmResourceGroup -Name $resourceGroupName -Location $resourceGroupLocation
}
else {
    Write-Output "Using existing resource group '$ResourceGroupName'"
}

# Start the deployment
Write-Output "Starting deployment"
if ( Test-Path $ParametersFilePath ) {
    New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFilePath -TemplateParameterFile $ParametersFilePath
}
else {
    New-AzureRmResourceGroupDeployment -ResourceGroupName $ResourceGroupName -TemplateFile $TemplateFilePath
}