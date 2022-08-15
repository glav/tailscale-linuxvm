param (
    [Parameter()]
    $AdminUserName,
    [Parameter()]
    $AdminUserPassword

)

$rg="tailscale-test"

az group create --location AustraliaEast --resource-group $rg

az deployment group create --resource-group $rg --template-file .\main.bicep  --parameters vmAdminUsername=$AdminUserName vmAdminPassword=$AdminUserPassword
