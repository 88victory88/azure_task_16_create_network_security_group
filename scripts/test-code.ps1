$scriptContent = Get-Content ./task.ps1

if ($scriptContent | Where-Object {$_.ToLower().Contains("new-azresourcegroup")}) { 
    Write-Host "Checking if script creates a resource group - ok" 
} else { 
    throw "Script is not creating a resource group, please review it. "
} 

if ($scriptContent | Where-Object {$_.ToLower().Contains("new-azvirtualnetworksubnetconfig")}) { 
    Write-Host "Checking if script creates subnets - ok" 
} else { 
    throw "Script is not creating subnets, please review it. "
}

if ($scriptContent | Where-Object {$_.ToLower().Contains("new-azvirtualnetwork")}) { 
    Write-Host "Checking if script creates a virtual network - ok" 
} else {
    throw "Script is not creating a virtual network, please review it. "
} 

if ($scriptContent | Where-Object {$_.ToLower().Contains("new-aznetworksecurityruleconfig")}) {
    Write-Host "Checking if script creates a NSG config - ok"
} else {
    throw "Script is not creating a NSG config, please review it. "
} 

if ($scriptContent | Where-Object {$_.ToLower().Contains("new-aznetworksecuritygroup")}) { 
    Write-Host "Checking if script creates a NSG - ok" 
} else { 
    throw "Script is not creating a NSG, please review it. "
} 
