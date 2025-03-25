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

# Creating NSG for Webservers
Write-Host "Creating webservers NSG..."
$webNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $webSubnetName

# ДAllow only HTTP/HTTPS from the Internet
$webNsg = Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $webNsg -Name "Allow-HTTP-HTTPS" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
    -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 80-443

Set-AzNetworkSecurityGroup -NetworkSecurityGroup $webNsg

# Creating an NSG for Management
Write-Host "Creating management NSG..."
$mngNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $mngSubnetName

# Allow SSH from the Internet only
$mngNsg = Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $mngNsg -Name "Allow-SSH" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
    -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 22

Set-AzNetworkSecurityGroup -NetworkSecurityGroup $mngNsg

# Creating NSG for Database
Write-Host "Creating database NSG..."
$dbNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name $dbSubnetName

# Important: You DO NOT need to add any Internet rules for the database NSG!
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $dbNsg

# Allow traffic between subnets in each NSG
$internalRuleName = "Allow-VNet"
$internalRulePriority = 120
$internalRuleProtocol = "*"
$internalRuleSource = "VirtualNetwork"
$internalRuleDestination = "VirtualNetwork"

$webNsg = Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $webNsg -Name $internalRuleName `
    -Access Allow -Protocol $internalRuleProtocol -Direction Inbound -Priority $internalRulePriority `
    -SourceAddressPrefix $internalRuleSource -SourcePortRange * `
    -DestinationAddressPrefix $internalRuleDestination -DestinationPortRange *

$mngNsg = Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $mngNsg -Name $internalRuleName `
    -Access Allow -Protocol $internalRuleProtocol -Direction Inbound -Priority $internalRulePriority `
    -SourceAddressPrefix $internalRuleSource -SourcePortRange * `
    -DestinationAddressPrefix $internalRuleDestination -DestinationPortRange *

$dbNsg = Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $dbNsg -Name $internalRuleName `
    -Access Allow -Protocol $internalRuleProtocol -Direction Inbound -Priority $internalRulePriority `
    -SourceAddressPrefix $internalRuleSource -SourcePortRange * `
    -DestinationAddressPrefix $internalRuleDestination -DestinationPortRange *

Set-AzNetworkSecurityGroup -NetworkSecurityGroup $webNsg
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $mngNsg
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $dbNsg
# $internalRule = New-AzNetworkSecurityRuleConfig -Name "Allow-VNet" `
#     -Access Allow -Protocol * -Direction Inbound -Priority 120 `
#     -SourceAddressPrefix VirtualNetwork -SourcePortRange * `
#     -DestinationAddressPrefix VirtualNetwork -DestinationPortRange *

# $webNsg = Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $webNsg -SecurityRules $internalRule
# $mngNsg = Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $mngNsg -SecurityRules $internalRule
# $dbNsg = Add-AzNetworkSecurityRuleConfig -NetworkSecurityGroup $dbNsg -SecurityRules $internalRule

# Set-AzNetworkSecurityGroup -NetworkSecurityGroup $webNsg
# Set-AzNetworkSecurityGroup -NetworkSecurityGroup $mngNsg
# Set-AzNetworkSecurityGroup -NetworkSecurityGroup $dbNsg

# Creating a virtual network and binding NSG to subnets
Write-Host "Creating virtual network..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroupId $webNsg.Id
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroupId $dbNsg.Id
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroupId $mngNsg.Id

New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location `
    -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet, $dbSubnet, $mngSubnet
