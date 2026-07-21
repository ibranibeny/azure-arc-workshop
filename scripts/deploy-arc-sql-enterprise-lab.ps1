<#
.SYNOPSIS
    Deploy SQL Server 2022 Enterprise on an Azure VM and onboard it to Azure Arc.

.DESCRIPTION
    LAB / EVALUATION ONLY. SQL Server enabled by Azure Arc does not support SQL
    Server in Azure Virtual Machines. This script deliberately follows the Azure VM
    Arc evaluation procedure, switches the Azure SQL VM resource to AHUB, simulates
    an on-premises host, and installs the Arc SQL extension with LicenseType=Paid.

    Use -AcceptUnsupportedLab to acknowledge the unsupported configuration and the
    requirement for qualifying SQL Server Enterprise licenses with Software Assurance
    or a SQL Server subscription.

.PARAMETER AcceptUnsupportedLab
    Required for deployment. Confirms that this is an unsupported, billable lab and
    that Enterprise AHUB/Paid licensing is covered by qualifying licenses.

.PARAMETER Cleanup
    Delete the dedicated resource group and onboarding service principal, then exit.

.PARAMETER OpenAllInboundPorts
    Add an NSG rule allowing all inbound traffic. INSECURE; isolated labs only.

.NOTES
    Requires Azure CLI authenticated with sufficient Azure and Microsoft Entra rights.
    Runs on Windows PowerShell 5.1 or PowerShell 7+.
#>
[CmdletBinding()]
param(
    [string]$Location = 'indonesiacentral',
    [string]$ArcLocation = 'southeastasia',
    [string]$ResourceGroup = 'rg-arc-eval-ent',
    [string]$VmName = 'arc-sql-ent',
    [string]$VmSize = 'Standard_D4s_v5',
    [string]$AdminUser = 'azureuser',
    [string]$AdminPassword,
    [string]$SpName = 'sp-arc-eval-ent',
    [switch]$AcceptUnsupportedLab,
    [switch]$OpenAllInboundPorts,
    [switch]$Cleanup
)

$ErrorActionPreference = 'Continue'
$ImagePublisher = 'MicrosoftSQLServer'
$ImageOffer = 'sql2022-ws2022'
$ImageSku = 'enterprise-gen2'
$ImageUrn = 'MicrosoftSQLServer:sql2022-ws2022:enterprise-gen2:latest'

function Assert-AzSuccess {
    param([Parameter(Mandatory)][string]$Operation)

    if ($LASTEXITCODE -ne 0) {
        throw "$Operation failed (Azure CLI exit code $LASTEXITCODE)."
    }
}

function Assert-Az {
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw 'Azure CLI (az) was not found. Install it from https://aka.ms/installazurecli.'
    }

    az account show 1>$null 2>$null
    Assert-AzSuccess 'Azure authentication check'
}

function New-LabPassword {
    $chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789'
    return (-join (1..20 | ForEach-Object {
        $chars[(Get-Random -Maximum $chars.Length)]
    })) + 'Aa9!'
}

function Test-Vm {
    az vm show --resource-group $ResourceGroup --name $VmName 1>$null 2>$null
    if ($LASTEXITCODE -ne 0) {
        return $false
    }

    $image = az vm show --resource-group $ResourceGroup --name $VmName `
        --query 'storageProfile.imageReference.{publisher:publisher,offer:offer,sku:sku}' -o json |
        ConvertFrom-Json
    Assert-AzSuccess "Read image identity for VM '$VmName'"

    if ($image.publisher -ine $ImagePublisher -or
        $image.offer -ine $ImageOffer -or
        $image.sku -ine $ImageSku) {
        throw "VM '$VmName' exists but does not use $ImagePublisher`:$ImageOffer`:$ImageSku. Use a different VM name or resource group."
    }

    $power = az vm show -d --resource-group $ResourceGroup --name $VmName `
        --query powerState -o tsv
    Assert-AzSuccess "Read power state for VM '$VmName'"
    Write-Host "VM '$VmName' exists and uses the required Enterprise image ($power)." -ForegroundColor Cyan

    if ($power -ne 'VM running') {
        az vm start --resource-group $ResourceGroup --name $VmName -o none
        Assert-AzSuccess "Start VM '$VmName'"
    }

    return $true
}

function Assert-DeploymentPreflight {
    Write-Host '>> Validating Marketplace image and VM SKU...' -ForegroundColor Green

    az vm image show --location $Location --urn $ImageUrn -o none
    Assert-AzSuccess "Validate image '$ImageUrn' in '$Location'"

    $sku = az vm list-skus --location $Location --resource-type virtualMachines `
        --size $VmSize --all --query "[?name=='$VmSize'] | [0]" -o json |
        ConvertFrom-Json
    Assert-AzSuccess "Validate VM size '$VmSize' in '$Location'"

    if (-not $sku -or $sku.name -ne $VmSize) {
        throw "VM size '$VmSize' is unavailable in '$Location'."
    }
    if ($sku.restrictions -and $sku.restrictions.Count -gt 0) {
        throw "VM size '$VmSize' is restricted in '$Location': $($sku.restrictions | ConvertTo-Json -Compress)"
    }
}

function Invoke-InGuest {
    param(
        [Parameter(Mandatory)][string]$ScriptText,
        [Parameter(Mandatory)][string]$Label
    )

    $path = Join-Path ([System.IO.Path]::GetTempPath()) `
        ("arc-sql-enterprise-" + [guid]::NewGuid().ToString('N') + '.ps1')
    Set-Content -Path $path -Value $ScriptText -Encoding UTF8

    if ($env:OS -eq 'Windows_NT') {
        $acl = Get-Acl -Path $path
        $acl.SetAccessRuleProtection($true, $false)
        $identity = [System.Security.Principal.WindowsIdentity]::GetCurrent().Name
        $rule = New-Object System.Security.AccessControl.FileSystemAccessRule(
            $identity,
            'FullControl',
            'Allow'
        )
        $acl.AddAccessRule($rule)
        Set-Acl -Path $path -AclObject $acl
    }

    try {
        Write-Host ">> $Label..." -ForegroundColor Green
        az vm run-command invoke --resource-group $ResourceGroup --name $VmName `
            --command-id RunPowerShellScript --scripts "@$path" -o none
        Assert-AzSuccess $Label
    }
    finally {
        Remove-Item $path -Force -ErrorAction SilentlyContinue
    }
}

function Open-AllInbound {
    Write-Host '>> Opening every inbound port (INSECURE; lab only)...' -ForegroundColor Red

    $nicId = az vm show --resource-group $ResourceGroup --name $VmName `
        --query 'networkProfile.networkInterfaces[0].id' -o tsv
    Assert-AzSuccess "Get NIC for VM '$VmName'"

    $nsgId = az network nic show --ids $nicId --query networkSecurityGroup.id -o tsv
    Assert-AzSuccess 'Get NIC NSG'

    if ([string]::IsNullOrWhiteSpace($nsgId)) {
        $nsgName = "$VmName-nsg"
        az network nsg create --resource-group $ResourceGroup --name $nsgName `
            --location $Location -o none
        Assert-AzSuccess "Create NSG '$nsgName'"
        az network nic update --ids $nicId --network-security-group $nsgName -o none
        Assert-AzSuccess "Attach NSG '$nsgName'"
    }
    else {
        $nsgName = ($nsgId -split '/')[-1]
    }

    az network nsg rule create --resource-group $ResourceGroup --nsg-name $nsgName `
        --name AllowAllInbound --priority 100 --direction Inbound --access Allow `
        --protocol '*' --source-address-prefixes '*' --source-port-ranges '*' `
        --destination-address-prefixes '*' --destination-port-ranges '*' -o none
    Assert-AzSuccess "Create AllowAllInbound on '$nsgName'"
}

function Remove-Lab {
    Write-Host "Deleting resource group '$ResourceGroup' asynchronously..." -ForegroundColor Red
    az group delete --name $ResourceGroup --yes --no-wait
    if ($LASTEXITCODE -ne 0) {
        Write-Warning "Resource group '$ResourceGroup' was not found or could not be deleted."
    }

    $appId = az ad sp list --display-name $SpName --query '[0].appId' -o tsv 2>$null
    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($appId)) {
        az ad sp delete --id $appId
        Assert-AzSuccess "Delete onboarding service principal '$SpName'"
    }

    Write-Host 'Cleanup started.' -ForegroundColor Yellow
}

function Set-SqlVmAhub {
    Write-Host '>> Registering Azure SQL VM management with AHUB licensing...' -ForegroundColor Green

    az provider register --namespace Microsoft.SqlVirtualMachine --wait
    Assert-AzSuccess 'Register Microsoft.SqlVirtualMachine provider'

    az sql vm show --resource-group $ResourceGroup --name $VmName 1>$null 2>$null
    if ($LASTEXITCODE -eq 0) {
        az sql vm update --resource-group $ResourceGroup --name $VmName `
            --license-type AHUB -o none
        Assert-AzSuccess "Update SQL VM '$VmName' to AHUB"
    }
    else {
        az sql vm create --resource-group $ResourceGroup --name $VmName `
            --location $Location --license-type AHUB -o none
        Assert-AzSuccess "Register SQL VM '$VmName' with AHUB"
    }

    $licenseType = az sql vm show --resource-group $ResourceGroup --name $VmName `
        --query sqlServerLicenseType -o tsv
    Assert-AzSuccess "Verify SQL VM '$VmName' license"
    if ($licenseType -ne 'AHUB') {
        throw "SQL VM license verification failed. Expected AHUB, received '$licenseType'."
    }
}

function New-OnboardingCredential {
    param(
        [Parameter(Mandatory)][string]$Scope
    )

    Write-Host ">> Preparing onboarding service principal '$SpName'..." -ForegroundColor Green
    $appId = az ad sp list --display-name $SpName --query '[0].appId' -o tsv 2>$null

    if ($LASTEXITCODE -eq 0 -and -not [string]::IsNullOrWhiteSpace($appId)) {
        $credential = az ad app credential reset --id $appId --append `
            --display-name "arc-lab-$((Get-Date).ToUniversalTime().ToString('yyyyMMddHHmmss'))" `
            --years 1 -o json | ConvertFrom-Json
        Assert-AzSuccess "Reset credential for '$SpName'"
    }
    else {
        $credential = az ad sp create-for-rbac --name $SpName `
            --role 'Azure Connected Machine Onboarding' --scopes $Scope -o json |
            ConvertFrom-Json
        Assert-AzSuccess "Create onboarding service principal '$SpName'"
        $appId = $credential.appId
    }

    az role assignment create --assignee $appId `
        --role 'Azure Connected Machine Onboarding' --scope $Scope -o none 2>$null
    if ($LASTEXITCODE -ne 0) {
        $assignment = az role assignment list --assignee $appId --scope $Scope `
            --role 'Azure Connected Machine Onboarding' --query '[0].id' -o tsv 2>$null
        if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrWhiteSpace($assignment)) {
            throw "Assign Azure Connected Machine Onboarding to '$SpName' failed."
        }
    }

    return [pscustomobject]@{
        AppId = $appId
        Password = $credential.password
    }
}

Assert-Az

if ($Cleanup) {
    Remove-Lab
    return
}

if (-not $AcceptUnsupportedLab) {
    throw 'Deployment blocked. Re-run with -AcceptUnsupportedLab after reviewing the unsupported Azure VM + Arc SQL design and licensing requirements.'
}

Write-Warning 'LAB ONLY: SQL Server in Azure Virtual Machines is unsupported by SQL Server enabled by Azure Arc.'
Write-Warning 'This run attests that SQL Server Enterprise is covered by qualifying Software Assurance or a SQL subscription.'

Assert-DeploymentPreflight

az group create --name $ResourceGroup --location $Location -o none
Assert-AzSuccess "Create resource group '$ResourceGroup'"

$vmExists = Test-Vm
if (-not $vmExists) {
    if ([string]::IsNullOrWhiteSpace($AdminPassword)) {
        $AdminPassword = New-LabPassword
        $script:PasswordGenerated = $true
        Write-Host "Generated VM administrator password: $AdminPassword" -ForegroundColor Magenta
    }

    Write-Host ">> Creating SQL Server 2022 Enterprise VM '$VmName' in '$Location'..." -ForegroundColor Green
    az vm create --resource-group $ResourceGroup --name $VmName `
        --location $Location `
        --image 'MicrosoftSQLServer:sql2022-ws2022:enterprise-gen2:latest' `
        --size $VmSize --admin-username $AdminUser --admin-password $AdminPassword `
        --public-ip-sku Standard --nsg-rule NONE -o none
    Assert-AzSuccess "Create Enterprise SQL VM '$VmName'"
}

if ($OpenAllInboundPorts) {
    Open-AllInbound
}

Set-SqlVmAhub

az connectedmachine show --resource-group $ResourceGroup --name $VmName 1>$null 2>$null
$arcAlreadyConnected = $LASTEXITCODE -eq 0

if (-not $arcAlreadyConnected) {
    $prepare = @'
[System.Environment]::SetEnvironmentVariable('MSFT_ARC_TEST', 'true', [System.EnvironmentVariableTarget]::Machine)
Set-Service WindowsAzureGuestAgent -StartupType Disabled

$rules = @(
    @{ Name = 'BlockAzureIMDS'; DisplayName = 'Block access to Azure IMDS'; Address = '169.254.169.254' },
    @{ Name = 'BlockAzureLocalIMDS'; DisplayName = 'Block access to Azure Local IMDS'; Address = '169.254.169.253' }
)
foreach ($rule in $rules) {
    if (Get-NetFirewallRule -Name $rule.Name -ErrorAction SilentlyContinue) {
        Set-NetFirewallRule -Name $rule.Name -Enabled True -Profile Any -Direction Outbound -Action Block
    }
    else {
        New-NetFirewallRule -Name $rule.Name -DisplayName $rule.DisplayName -Enabled True -Profile Any -Direction Outbound -Action Block -RemoteAddress $rule.Address
    }
}
'@
    Invoke-InGuest -ScriptText $prepare -Label 'Prepare VM for Azure Arc evaluation'

    $subscriptionId = az account show --query id -o tsv
    Assert-AzSuccess 'Read subscription ID'
    $tenantId = az account show --query tenantId -o tsv
    Assert-AzSuccess 'Read tenant ID'
    $scope = "/subscriptions/$subscriptionId/resourceGroups/$ResourceGroup"
    $credential = New-OnboardingCredential -Scope $scope

    $appId = $credential.AppId
    $secret = $credential.Password
    $onboard = @"
`$work = 'C:\ArcLab'
New-Item -ItemType Directory -Force -Path `$work | Out-Null
Invoke-WebRequest -Uri 'https://aka.ms/AzureConnectedMachineAgent' -OutFile "`$work\azcm.msi"
Start-Process msiexec.exe -ArgumentList "/i ```"`$work\azcm.msi```" /qn" -Wait
`$agent = "`$env:ProgramFiles\AzureConnectedMachineAgent\azcmagent.exe"
& `$agent connect --service-principal-id '$appId' --service-principal-secret '$secret' --tenant-id '$tenantId' --subscription-id '$subscriptionId' --resource-group '$ResourceGroup' --location '$ArcLocation'
if (`$LASTEXITCODE -ne 0) { throw "azcmagent connect failed with exit code `$LASTEXITCODE" }
"@
    Invoke-InGuest -ScriptText $onboard -Label 'Install Connected Machine agent and connect to Azure Arc'
    $secret = $null
    $credential = $null
    $onboard = $null
}
else {
    Write-Host "Azure Arc machine '$VmName' already exists; skipping Guest Agent-dependent onboarding." -ForegroundColor Cyan
}

Write-Host '>> Installing Azure extension for SQL Server (LicenseType=Paid)...' -ForegroundColor Green
$settings = '{"SqlManagement":{"IsEnabled":true},"LicenseType":"Paid","ExcludedSqlInstances":[]}'
$settingsPath = Join-Path ([System.IO.Path]::GetTempPath()) `
    ("arc-sql-settings-" + [guid]::NewGuid().ToString('N') + '.json')
Set-Content -Path $settingsPath -Value $settings -Encoding UTF8
try {
    az connectedmachine extension show --resource-group $ResourceGroup `
        --machine-name $VmName --name WindowsAgent.SqlServer 1>$null 2>$null
    if ($LASTEXITCODE -eq 0) {
        az connectedmachine extension update --machine-name $VmName `
            --resource-group $ResourceGroup --name WindowsAgent.SqlServer `
            --settings "@$settingsPath" --enable-auto-upgrade true -o none
        Assert-AzSuccess 'Update Azure extension for SQL Server'
    }
    else {
        az connectedmachine extension create --machine-name $VmName `
            --resource-group $ResourceGroup --location $ArcLocation `
            --name WindowsAgent.SqlServer --type WindowsAgent.SqlServer `
            --publisher Microsoft.AzureData --settings "@$settingsPath" `
            --enable-auto-upgrade true -o none
        Assert-AzSuccess 'Install Azure extension for SQL Server'
    }
}
finally {
    Remove-Item $settingsPath -Force -ErrorAction SilentlyContinue
}

if (-not $arcAlreadyConnected) {
    Write-Host '>> Rebooting VM to stop the disabled Azure Guest Agent...' -ForegroundColor Green
    az vm restart --resource-group $ResourceGroup --name $VmName -o none
    Assert-AzSuccess "Restart VM '$VmName'"
}

$power = az vm show -d --resource-group $ResourceGroup --name $VmName --query powerState -o tsv 2>$null
Assert-AzSuccess 'Read final VM power state'
$sqlVmLicense = az sql vm show --resource-group $ResourceGroup --name $VmName --query sqlServerLicenseType -o tsv 2>$null
Assert-AzSuccess 'Read final Azure SQL VM license type'
$arcStatus = az connectedmachine show --resource-group $ResourceGroup --name $VmName --query status -o tsv 2>$null
Assert-AzSuccess 'Read final Arc machine status'
$arcSqlState = az connectedmachine extension show --resource-group $ResourceGroup `
    --machine-name $VmName --name WindowsAgent.SqlServer --query provisioningState -o tsv 2>$null
Assert-AzSuccess 'Read final Arc SQL extension state'
$publicIp = az vm show -d --resource-group $ResourceGroup --name $VmName --query publicIps -o tsv 2>$null
Assert-AzSuccess 'Read final VM public IP'

Write-Host "`n================= Deployment summary =================" -ForegroundColor Cyan
Write-Host ("Resource group       : {0}" -f $ResourceGroup)
Write-Host ("VM name              : {0}" -f $VmName)
Write-Host ("VM region            : {0}" -f $Location)
Write-Host ("Arc region           : {0}" -f $ArcLocation)
Write-Host ("VM image             : {0}" -f $ImageUrn)
Write-Host ("Public IP            : {0}" -f $publicIp)
Write-Host ("VM power state       : {0}" -f $power)
Write-Host ("Azure SQL VM license : {0}" -f $sqlVmLicense)
Write-Host ("Arc server status    : {0}" -f $arcStatus)
Write-Host ("Arc SQL extension    : {0}" -f $arcSqlState)
Write-Host ("Arc SQL license      : Paid")
Write-Host ("Admin user           : {0}" -f $AdminUser)
if ($script:PasswordGenerated) {
    Write-Host 'Admin password       : generated and shown earlier in this terminal' -ForegroundColor Magenta
}
Write-Host '======================================================' -ForegroundColor Cyan
Write-Host ("Cleanup: .\deploy-arc-sql-enterprise-lab.ps1 -ResourceGroup {0} -SpName {1} -Cleanup" -f $ResourceGroup, $SpName) -ForegroundColor Yellow
