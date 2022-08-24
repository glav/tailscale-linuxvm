param (
    [Parameter()]
    $ResourceGroup,
    [Parameter()]
    $VmName,
    [Parameter()]
    $AdminUserName,
    [Parameter()]
    $AdminUserPassword,
    [Parameter()]
    $IotHubName

)

$rg="tailscale-test"

#Ensure the subscription cleaner deletes this group after  one day
#TODO: Parametrise this so that we can optionally pass in the expiresOn tag value or not.
$deleteDate = get-date -Format yyyy-MM-dd
az group create --location AustraliaEast --resource-group $ResourceGroup --tags expiresOn=$deleteDate

az deployment group create --resource-group $rg --template-file .\main.bicep  --parameters vmAdminUsername=$AdminUserName vmAdminPassword=$AdminUserPassword vmName=$VmName hubName=$IotHubName

