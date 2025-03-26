# --- Input variables ---
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

# --- Creating NSGs before subnets ---
Write-Host "Creating web network security group..."
$webNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name "$webSubnetName-NSG"

Write-Host "Creating management network security group..."
$mngNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name "$mngSubnetName-NSG"

Write-Host "Creating database network security group..."
$dbNsg = New-AzNetworkSecurityGroup -ResourceGroupName $resourceGroupName -Location $location -Name "$dbSubnetName-NSG"

# --- Creating Virtual Network and subnets ---
Write-Host "Creating a virtual network ..."
$webSubnet = New-AzVirtualNetworkSubnetConfig -Name $webSubnetName -AddressPrefix $webSubnetIpRange -NetworkSecurityGroupId $webNsg.Id
$dbSubnet = New-AzVirtualNetworkSubnetConfig -Name $dbSubnetName -AddressPrefix $dbSubnetIpRange -NetworkSecurityGroupId $dbNsg.Id
$mngSubnet = New-AzVirtualNetworkSubnetConfig -Name $mngSubnetName -AddressPrefix $mngSubnetIpRange -NetworkSecurityGroupId $mngNsg.Id

New-AzVirtualNetwork -Name $virtualNetworkName -ResourceGroupName $resourceGroupName -Location $location -AddressPrefix $vnetAddressPrefix -Subnet $webSubnet,$dbSubnet,$mngSubnet

# --- Configuring NSG rules ---
Write-Host "Configuring security rules..."

# Rule for Web NSG: allows HTTP/HTTPS traffic
$webRule = New-AzNetworkSecurityRuleConfig -Name "Allow-WEB" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
    -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 80,443

$webNsg.SecurityRules += $webRule
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $webNsg

# Rule for Management NSG: allows SSH
$mngRule = New-AzNetworkSecurityRuleConfig -Name "Allow-SSH" `
    -Access Allow -Protocol Tcp -Direction Inbound -Priority 100 `
    -SourceAddressPrefix Internet -SourcePortRange * `
    -DestinationAddressPrefix * -DestinationPortRange 22

$mngNsg.SecurityRules += $mngRule
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $mngNsg

# Updating NSG for the database (without new rules)
Set-AzNetworkSecurityGroup -NetworkSecurityGroup $dbNsg

Write-Host "Azure infrastructure deployment completed successfully!"
