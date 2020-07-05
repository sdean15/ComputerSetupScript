#ip regex pattern(not tested)
$ipPattern = '^([1-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])(\.([0-9]|[1-9][0-9]|1[0-9][0-9]|2[0-4][0-9]|25[0-5])){3}$'


#function for input validation exception handling
Function validateIP($text){

    do{
        try{
            [ipaddress]$validatedIP = Read-Host $text
        }catch{"Error: Not a valid IP address."}
    
    }until($?)

    Return $validatedIP
}


#get all user inputs
$ipaddress = validateIP("Enter IP address")
$defaultGateway = validateIP("Enter Default gateway")
$dns1 = validateIP("Enter first DNS address")
$dns2 = validateIP("Enter second DNS address")

do{
    $compName = Read-Host "Enter computer name to be set"
}while($compName -eq [string]::Empty)

$compDesc = Read-Host "Enter computer description"


#Function to execute all needed commands
#TODO: add exception handling!
Function executeCommands() {

    #change ip address
    Write-Host "Setting IP address, Subnet mask, and Default gateway..."
    try{
        New-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress $ipaddress -PrefixLength 24 -DefaultGateway $defaultgateway
        Write-Host "Finished"
    }catch [System.SystemException]{"IP or default gateway already exits."}


    #set DNS addresses
    Write-Host "Setting DNS servers..."
    try{
        Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses $dns1, $dns2
        Write-Host "Finished"
    }catch{}

    #rename the pc
    Write-Host "Setting Computer Name..."
    try{
        Rename-Computer -NewName $compName
        Write-Host "Finished"
    }catch{}

    #set computer description using a temp var
    Write-Host "Setting Computer Description..."
    try{
        $temp = Get-WmiObject Win32_OperatingSystem
        $temp.Description = $compDesc
        $temp.Put()
        Write-Host "Finished"
    }catch{}
    

    Remove-Variable temp
    Write-Host "Changes complete!"
}


Function verifyData() {

$currentIP = (Get-NetIPConfiguration).IPv4Address.IPAddress
$currentDG = (Get-NetIPConfiguration).IPv4DefaultGateway.NextHop
$currentDNS = (Get-NetIPConfiguration).DNSServer.ServerAddresses #may have to create list
#Get-DnsClientServerAddress
$currentName = (Get-ComputerInfo).CsDNSHostName
$currentDesc = (Get-WmiObject Win32_OperatingSystem).Description
$allVerified = $true

Write-Host "Verifying changes made..."

#verify IP change
if($currentIP -ne $ipaddress)
{
    Write-Host "IP not set to $($ipaddress). IP currently set to $($currentIP)."
    $allVerified = $false
}

#verify default gateway
if($currentDG -ne $defaultGateway)
{
    Write-Host "Default gateway not set to $($defaultGateway). Currently set to $($currentDG)."
    $allVerified = $false
}

#verify DNS
#need to create list for multiple addresses
if($currentDG -ne $defaultGateway)
{
    Write-Host "DNS not set to $($dns1). Currently set to $($currentDNS)."
    $allVerified = $false
}

#verify computer name
#if($currentName -ne $compName)
#{
#    Write-Host "Computer name not set to $($compName). Currently set to $($currentName). Restart required."
#    $allVerified = $false
#}


#verify computer description
if($currentDesc -ne $compDesc)
{
    Write-Host "Computer description not set to $($compDesc). Currently set to $($currentDesc)."
    $allVerified = $false
}


if($allVerified)
{
    Write-Host "All changes verified"
}else { Write-Host "Not all changes were verified"}

Remove-Variable currentIP
Remove-Variable currentDG
Remove-Variable currentDNS
Remove-Variable currentName
Remove-Variable currentDesc


}


#read-back inputs
Write-Host "`nSettings`n---------------------------------"
Write-Host ("IP address......................: $($ipaddress)")
Write-Host ("Default Gateway.................: $($defaultgateway)")
Write-Host ("DNS 1...........................: $($dns1)")
Write-Host ("DNS 2...........................: $($dns2)")
Write-Host ("Computer Name...................: $($compName)")
Write-Host ("Computer Description............: $($compDesc)")


#confirmation
$title = 'Computer Setup'
$prompt = 'Do you want to proceed with these settings?'
$choices = '&Yes', '&No'
$decision = $Host.UI.PromptForChoice($title, $prompt, $choices, 1)
if($decision -eq 0){ executeCommands } else {Break}

verifyData

#remove vars
Remove-Variable ipaddress
Remove-Variable defaultGateway
Remove-Variable dns1
Remove-Variable dns2
Remove-Variable compName
Remove-Variable compDesc
Write-Host "Proccess Completed"
Pause