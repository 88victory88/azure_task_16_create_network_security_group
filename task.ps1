$location = "uksouth"
$resourceGroupName = "mate-azure-task-16"

$virtualNetworkName = "todoapp"
$vnetAddressPrefix = "10.20.30.0/24"
$webSubnetName = "webservers"
$webSubnetIpRange = "10.20.30.0/26"
$dbSubnetName = "database"
$dbSubnetIpRange = "10.20.30.64/26"
$mngSubnetName = "management"
$mngSubnetIpRange = "10.20.30.128/26"

Write-Host "Creating a resource group $resourceGroupName ..."
New-AzResourceGroup -Name $resourceGroupName -Location $location

# --- Creating Web NSG ---
Write-Host "Creating web network security group..."
$webNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name "$webSubnetName-NSG"

# Allow only HTTP/HTTPS traffic from Internet
$webNsg = Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $webNsg -Name "Allow-HTTP" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix Internet `
    -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 80,443

Set-AzNetworkSecurityGroup -NetworkSecurityGroup $webNsg

# --- Creating Management NSG ---
Write-Host "Creating management network security group..."
$mngNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name "$mngSubnetName-NSG"

# Allow SSH from Internet
$mngNsg = Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $mngNsg -Name "Allow-SSH" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 -SourceAddressPrefix Internet `
    -SourcePortRange * -DestinationAddressPrefix * -DestinationPortRange 22

Set-AzNetworkSecurityGroup -NetworkSecurityGroup $mngNsg

# --- Creating Database NSG ---
Write-Host "Creating database network security group..."
$dbNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name "$dbSubnetName-NSG"

Set-AzNetworkSecurityGroup -NetworkSecurityGroup $dbNsg

# --- Creating Virtual Network and Subnets ---
Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroupId $webNsg.Id
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroupId $dbNsg.Id
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroupId $mngNsg.Id

New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$dbSubnet,$mngSubnet
