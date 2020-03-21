Function TK_CreateVPN {
    <#
        .SYNOPSIS
            Create a full functional VPN connection in Azure
        .DESCRIPTION
            Create a full functional VPN connection in Azure
        .PARAMETER ResourceGroupName
            The name of the ResourceGroup where the disk is stored eg. my-resources
        .PARAMETER VNetName
            The Name of the virtual network eg. myvnet
        .PARAMETER VNetPrefix
            The prefix of the virtual network eg. 10.0.0.0/16
        .PARAMETER SubnetName
            The name of the first subnet eg. Frontend 
        .PARAMETER SubnetPrefix
            The prefix of the first subnet (must be part of the virtual network) eg. 10.0.1.0/24
        .PARAMETER GWName
            The name of the VPN Gateway eg. vpngateway
        .PARAMETER GWPrefix
            The prefix of the Gateway Subnet (must be part of the virtual network) eg. 10.0.255.0/28
        .PARAMETER GWPIPName
            The Name of the public IP address for the Gateway eg. vpngwpip
        .PARAMETER RemoteGWIP
            The public IP address of the remote gateway eg. 92.50.79.201
        .PARAMETER LocalGWPName
            The Name of the local gateway eg. localgateway
        .PARAMETER RemoteNetworkPrefix
            The prefix of the remote reachable subnet eg. 192.168.0.0/24,192.168.1.0/24 etc.
        .PARAMETER PSKey
            The pres shared key (PSK) of the remote gateway eg. Azure@123456
        .EXAMPLE
            TK_CreateVPN -ResourceGroupName "my-resources"" -VNetName "myvnet" -VNetPrefix "10.0.0.0/16" -SubnetName "Frontend" -SubnetPrefix "10.0.1.0/24" -GWName "vpngateway" -GWPrefix "10.0.255.0/28" -GWPIPName "vpngwpip" -RemoteGWIP "92.50.79.201" -LocalGWPName "localgateway" -RemoteNetworkPrefix "192.168.0.0/24,192.168.1.0/24" -PSKey "Azure@123456"
        .NOTES
            Author        : Thomas Krampe | t.krampe@loginconsultants.de
            Version       : 1.0
            Creation date : 23.08.2019 | v0.1 | Initial script
            Last change   : 23.08.2019 | v1.0 | Release
           
            IMPORTANT NOTICE
            ----------------
            THIS SCRIPT IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING
            ANY WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE OR NON- INFRINGEMENT.
            LOGIN CONSULTANTS, SHALL NOT BE LIABLE FOR TECHNICAL OR EDITORIAL ERRORS OR OMISSIONS CONTAINED 
            HEREIN, NOT FOR DIRECT, INCIDENTAL, CONSEQUENTIAL OR ANY OTHER DAMAGES RESULTING FROM FURNISHING,
            PERFORMANCE, OR USE OF THIS SCRIPT, EVEN IF LOGIN CONSULTANTS HAS BEEN ADVISED OF THE POSSIBILITY
            OF SUCH DAMAGES IN ADVANCE.
    #>
    
    [CmdletBinding()]
    Param( 
        [Parameter(Mandatory = $true)][String]$ResourceGroupName,
        [Parameter(Mandatory = $true)][String]$VNetName,
        [Parameter(Mandatory = $true)][String]$VNetPrefix,
        [Parameter(Mandatory = $true)][String]$SubnetName,
        [Parameter(Mandatory = $true)][String]$SubnetPrefix,
        [Parameter(Mandatory = $true)][String]$GWName,
        [Parameter(Mandatory = $true)][String]$GWPrefix,
        [Parameter(Mandatory = $true)][String]$GWPIPName,
        [Parameter(Mandatory = $true)][String]$RemoteGWIP,
        [Parameter(Mandatory = $true)][String]$LocalGWPName,
        [Parameter(Mandatory = $true)][String]$RemoteNetworkPrefix,
        [Parameter(Mandatory = $true)][String]$PSKey
    )
  
    begin {
        Connect-AzAccount    
    }
  
    process {
        # Create ResourceGroup 
        New-AzResourceGroup -ResourceGroupName $ResourceGroupName -Location $RGLocation
        
        # Create Virtual Network
        $FEsubnet = New-AzVirtualNetworkSubnetConfig -Name $SubnetName -AddressPrefix $SubnetPrefix 
        $GWsubnet = New-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -AddressPrefix $GWPrefix 
        $vnet = New-AzVirtualNetwork -Name $VNetName -ResourceGroupName $ResourceGroupName -Location $RGLocation -AddressPrefix $VNetPrefix -Subnet $FEsubnet,$GWsubnet     

        # Create Public IP Address
        $gwpip = New-AzPublicIpAddress -Name $GWPIPName -ResourceGroupName $ResourceGroupName -Location $RGLocation -AllocationMethod Dynamic  
        $subnet = Get-AzVirtualNetworkSubnetConfig -Name "GatewaySubnet" -VirtualNetwork $vnet  
        $gwipconf = New-AzVirtualNetworkGatewayIpConfig -Name "VPNGWIPConfig" -Subnet $subnet -PublicIpAddress $gwpip 

        # Create VPn Gateway
        New-AzVirtualNetworkGateway -Name $GWName -ResourceGroupName $ResourceGroupName -Location $RGLocation -IpConfigurations $gwipconf -GatewayType Vpn -VpnType RouteBased -GatewaySku VpnGw1 

        # Create Local Gateway
        New-AzLocalNetworkGateway -Name $LocalGWPName -ResourceGroupName $ResourceGroupName -Location $RGLocation -GatewayIpAddress $RemoteGWIP -AddressPrefix $RemoteNetworkPrefix 
    
        # Create VPN Connection
        $MyVPNGW = Get-AzVirtualNetworkGateway -Name $GWName -ResourceGroupName $ResourceGroupName 
        $MyLocalGW = Get-AzLocalNetworkGateway -Name $LocalGWPName -ResourceGroupName $ResourceGroupName  
        New-AzVirtualNetworkGatewayConnection -Name "VPNConnection" -ResourceGroupName  $ResourceGroupName -Location $RGLocation -VirtualNetworkGateway1 $MyVPNGW -LocalNetworkGateway2 $MyLocalGW -ConnectionType IPsec -SharedKey $PSKey

        # Create user defined IKE Policy
        $connection = Get-AzVirtualNetworkGatewayConnection -Name "VPNConnection" -ResourceGroupName $ResourceGroupName  
        $newpolicy = New-AzIpsecPolicy -IkeEncryption AES256 -IkeIntegrity SHA256 -DhGroup DHGroup14 -IpsecEncryption AES128 -IpsecIntegrity SHA1 -PfsGroup PFS2048 -SALifeTimeSeconds 14400 -SADataSizeKilobytes 102400000  
        Set-AzVirtualNetworkGatewayConnection -VirtualNetworkGatewayConnection $connection -IpsecPolicies $newpolicy 

        # Check VPN connection
        $VPNconnection = Get-AzVirtualNetworkGatewayConnection -Name "VPNConnection" -ResourceGroupName $ResourceGroupName 
        if ($VPNconnection) {
            Write-Host $VPNconnection.IpsecPolicies 
            }
            
    }
  
    end {
     
    }
} #EndFunction TK_CreateVPN
