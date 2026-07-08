<#
.SYNOPSIS
    Evaluate Azure Arc-enabled servers on an Azure VM (Windows + SQL Server Evaluation).

.DESCRIPTION
    Creates or checks a Windows Server VM in Indonesia Central, prepares it to look like an
    on-premises server per Microsoft Learn (sets MSFT_ARC_TEST, disables the Azure Guest
    Agent, blocks both IMDS endpoints), installs SQL Server 2022 Evaluation, onboards the
    machine to Azure Arc, and enables the Azure extension for SQL Server.

    EVALUATION / TESTING ONLY. Installing Azure Arc-enabled servers on an Azure VM is not
    supported for production. Reference:
    https://learn.microsoft.com/azure/azure-arc/servers/plan-evaluate-on-azure-virtual-machine

.PARAMETER Cleanup
    Delete the resource group and onboarding service principal, then exit.

.PARAMETER SkipSql
    Skip installing SQL Server and enabling the SQL extension (VM + Arc only).

.EXAMPLE
    ./evaluate-arc-on-azure-vm.ps1

.EXAMPLE
    ./evaluate-arc-on-azure-vm.ps1 -Cleanup

.NOTES
    Requires: Azure CLI (az) signed in (run 'az login' first).
    Runs on PowerShell 7+ (pwsh) or Windows PowerShell 5.1.
#>
[CmdletBinding()]
param(
    [string]$Location       = "indonesiacentral",
    [string]$ResourceGroup  = "rg-arc-eval",
    [string]$VmName         = "arc-eval-sql",
    [string]$VmSize         = "Standard_D4s_v5",
    [string]$AdminUser      = "azureuser",
    [string]$SpName         = "sp-arc-eval",
    [switch]$SkipSql,
    [switch]$Cleanup
)

$ErrorActionPreference = "Stop"

function Assert-Az {
    if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
        throw "Azure CLI (az) not found. Install from https://aka.ms/installazurecli"
    }
    az account show 1>$null 2>$null
    if ($LASTEXITCODE -ne 0) { throw "Not signed in to Azure. Run 'az login' first." }
}

# --- Check VM availability & power state (create/start handled by caller) ---
function Test-Vm {
    az vm show -g $ResourceGroup -n $VmName 2>$null | Out-Null
    if ($LASTEXITCODE -eq 0) {
        $power = az vm show -d -g $ResourceGroup -n $VmName --query powerState -o tsv
        Write-Host "VM '$VmName' exists - power state: $power" -ForegroundColor Cyan
        if ($power -ne "VM running") {
            Write-Host "VM is not running - starting it..." -ForegroundColor Yellow
            az vm start -g $ResourceGroup -n $VmName | Out-Null
        }
        return $true
    }
    Write-Host "VM '$VmName' not found." -ForegroundColor Yellow
    return $false
}

# --- Run a PowerShell script inside the VM via az vm run-command (no RDP/SSH) ---
function Invoke-InGuest {
    param([string]$ScriptText, [string]$Label)
    $dir = [System.IO.Path]::GetTempPath()
    $ps1 = Join-Path $dir ("arc-eval-" + [guid]::NewGuid().ToString("N") + ".ps1")
    Set-Content -Path $ps1 -Value $ScriptText -Encoding UTF8
    Write-Host ">> $Label ..." -ForegroundColor Green
    az vm run-command invoke -g $ResourceGroup -n $VmName `
        --command-id RunPowerShellScript --scripts "@$ps1" -o none
    Remove-Item $ps1 -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# Cleanup shortcut
# ---------------------------------------------------------------------------
if ($Cleanup) {
    Write-Host "Deleting resource group '$ResourceGroup' (async)..." -ForegroundColor Red
    az group delete --name $ResourceGroup --yes --no-wait
    $appId = az ad sp list --display-name $SpName --query "[0].appId" -o tsv 2>$null
    if ($appId) { az ad sp delete --id $appId; Write-Host "Deleted service principal $SpName." }
    Write-Host "Cleanup started." -ForegroundColor Yellow
    return
}

Assert-Az

# ---------------------------------------------------------------------------
# Step 1 - Create OR check the VM (availability + power-state check)
# ---------------------------------------------------------------------------
az group create --name $ResourceGroup --location $Location -o none

if (-not (Test-Vm)) {
    $sec = Read-Host "Enter a strong VM admin password" -AsSecureString
    $pwd = [System.Net.NetworkCredential]::new("", $sec).Password
    Write-Host "Creating Windows Server 2022 VM in $Location..." -ForegroundColor Green
    az vm create `
        --resource-group $ResourceGroup --name $VmName `
        --image "MicrosoftWindowsServer:WindowsServer:2022-datacenter-azure-edition:latest" `
        --size $VmSize --admin-username $AdminUser --admin-password $pwd `
        --public-ip-sku Standard --nsg-rule NONE -o none
}

# ---------------------------------------------------------------------------
# Step 2 - Prepare the VM to look like on-premises (Microsoft Learn procedure)
# ---------------------------------------------------------------------------
$prep = @'
[System.Environment]::SetEnvironmentVariable("MSFT_ARC_TEST","true",[System.EnvironmentVariableTarget]::Machine)
Set-Service WindowsAzureGuestAgent -StartupType Disabled -Verbose
Stop-Service WindowsAzureGuestAgent -Force -Verbose
New-NetFirewallRule -Name BlockAzureIMDS -DisplayName "Block access to Azure IMDS" -Enabled True -Profile Any -Direction Outbound -Action Block -RemoteAddress 169.254.169.254
New-NetFirewallRule -Name BlockAzureLocalIMDS -DisplayName "Block access to Azure Local IMDS" -Enabled True -Profile Any -Direction Outbound -Action Block -RemoteAddress 169.254.169.253
'@
Invoke-InGuest -ScriptText $prep -Label "Prepare VM (MSFT_ARC_TEST, disable Guest Agent, block IMDS)"

# ---------------------------------------------------------------------------
# Step 3 - Install SQL Server 2022 Enterprise (Evaluation)
# ---------------------------------------------------------------------------
if (-not $SkipSql) {
    $sql = @'
$w="C:\ArcLab"; New-Item -ItemType Directory -Force -Path $w | Out-Null
Invoke-WebRequest -Uri "https://go.microsoft.com/fwlink/p/?linkid=2215158" -OutFile "$w\SQL2022-SSEI-Eval.exe"
& "$w\SQL2022-SSEI-Eval.exe" /ACTION=Download /MEDIATYPE=CAB /MEDIAPATH=$w /QUIET | Out-Null
$box = Get-ChildItem $w -Filter "SQLServer2022-*.exe" | Select-Object -First 1
& $box.FullName /X:"$w\media" /Q | Out-Null
& "$w\media\setup.exe" /Q /ACTION=Install /FEATURES=SQLENGINE /INSTANCENAME=MSSQLSERVER /SQLSYSADMINACCOUNTS="BUILTIN\Administrators" /TCPENABLED=1 /IACCEPTSQLSERVERLICENSETERMS /UPDATEENABLED=0
'@
    Invoke-InGuest -ScriptText $sql -Label "Install SQL Server 2022 Evaluation"
}

# ---------------------------------------------------------------------------
# Step 4 - Onboard the VM to Azure Arc
# ---------------------------------------------------------------------------
$sub    = az account show --query id -o tsv
$tenant = az account show --query tenantId -o tsv

Write-Host ">> Creating onboarding service principal '$SpName'..." -ForegroundColor Green
$sp = az ad sp create-for-rbac --name $SpName --role "Azure Connected Machine Onboarding" `
        --scopes "/subscriptions/$sub/resourceGroups/$ResourceGroup" -o json | ConvertFrom-Json
$appId  = $sp.appId
$secret = $sp.password
Start-Sleep -Seconds 20   # allow service principal to propagate

# $env:ProgramFiles must stay literal for the in-guest shell (escaped with a backtick).
$onboard = @"
Invoke-WebRequest -Uri https://aka.ms/AzureConnectedMachineAgent -OutFile C:\ArcLab\azcm.msi
Start-Process msiexec.exe -ArgumentList '/i C:\ArcLab\azcm.msi /qn' -Wait
& "`$env:ProgramFiles\AzureConnectedMachineAgent\azcmagent.exe" connect --service-principal-id $appId --service-principal-secret $secret --tenant-id $tenant --subscription-id $sub --resource-group $ResourceGroup --location $Location
"@
Invoke-InGuest -ScriptText $onboard -Label "Install Connected Machine agent and connect to Azure Arc"

# ---------------------------------------------------------------------------
# Step 5 - Enable the Azure extension for SQL Server (LicenseOnly for Evaluation)
# ---------------------------------------------------------------------------
if (-not $SkipSql) {
    Write-Host ">> Enabling Azure extension for SQL Server (LicenseType=LicenseOnly)..." -ForegroundColor Green
    $settings = '{"SqlManagement":{"IsEnabled":true},"LicenseType":"LicenseOnly","ExcludedSqlInstances":[]}'
    $sf = Join-Path ([System.IO.Path]::GetTempPath()) ("sqlsettings-" + [guid]::NewGuid().ToString("N") + ".json")
    Set-Content -Path $sf -Value $settings -Encoding UTF8
    az connectedmachine extension create `
        --machine-name $VmName --name "WindowsAgent.SqlServer" `
        --resource-group $ResourceGroup --location $Location `
        --type "WindowsAgent.SqlServer" --publisher "Microsoft.AzureData" `
        --settings "@$sf" -o none
    Remove-Item $sf -Force -ErrorAction SilentlyContinue
}

# ---------------------------------------------------------------------------
# Verify
# ---------------------------------------------------------------------------
Write-Host "`n=== Verification ===" -ForegroundColor Cyan
az connectedmachine show -g $ResourceGroup -n $VmName --query "{name:name, status:status}" -o table
$power = az vm show -d -g $ResourceGroup -n $VmName --query powerState -o tsv
Write-Host "VM hardware power state: $power"
Write-Host "`nDone. To remove everything, run:  ./evaluate-arc-on-azure-vm.ps1 -Cleanup" -ForegroundColor Yellow
