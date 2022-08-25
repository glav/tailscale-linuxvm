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
$grpResult = az group create --location AustraliaEast --resource-group $ResourceGroup --tags expiresOn=$deleteDate
if (!$grpResult) {
    Write-Error "Error creating the resource group [$ResourceGroup]"
    Write-Host "##vso[task.logissue type=error]Resource group creation failed."
    exit(1)
}

$output = az deployment group create --resource-group $rg --template-file .\main.bicep  --parameters vmAdminUsername=$AdminUserName vmAdminPassword=$AdminUserPassword vmName=$VmName hubName=$ --name InfraDeploymentPipeline
if (!$output) {
    Write-Error "Error deploying to resource group [$ResourceGroup]"
    Write-Host "##vso[task.logissue type=error]Depployment failed. Please check the detailed logs."
    exit(1)
}

  

