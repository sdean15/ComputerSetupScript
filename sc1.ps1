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
    Set-NetIPAddress -InterfaceAlias "Ethernet" -IPAddress $ipaddress -PrefixLength 24 -DefaultGateway $defaultgateway
    Write-Host "Finished"

    #set DNS addresses
    Write-Host "Setting DNS servers..."
    Set-DnsClientServerAddress -InterfaceAlias "Ethernet" -ServerAddresses $dns1, $dns2
    Write-Host "Finished"

    #rename the pc
    Write-Host "Setting Computer Name..."
    Rename-Computer -NewName $compName
    Write-Host "Finished"

    #set computer description using a temp var
    Write-Host "Setting Computer Description..."
    $temp = Get-WmiObject Win32_OperatingSystem
    $temp.Description = $compDesc
    $temp.Put()
    Write-Host "Finished"

    Remove-Variable temp
    Write-Host "Process complete!"
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

#remove vars
Remove-Variable ipaddress
Remove-Variable defaultGateway
Remove-Variable dns1
Remove-Variable dns2
Remove-Variable compName
Remove-Variable compDesc
Pause