# Arc SQL Enterprise Azure VM Lab Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add, verify, and run a guarded PowerShell workflow that deploys SQL Server 2022 Enterprise on an Azure VM and onboards the host and SQL instance to Azure Arc for lab evaluation.

**Architecture:** A new script remains separate from the existing Evaluation installer. It creates an Enterprise Marketplace VM, sets Azure SQL VM licensing to AHUB, applies Microsoft's Azure-VM-as-Arc evaluation preparation, connects through a scoped service principal, installs Arc SQL with `Paid`, and reboots only after all Guest Agent-dependent operations finish.

**Tech Stack:** PowerShell 5.1+, Azure CLI, Azure VM Run Command, Azure Connected Machine agent, Azure SQL IaaS Agent extension, Azure extension for SQL Server.

---

### Task 1: Add executable safety contract tests

**Files:**
- Create: `scripts/tests/test-deploy-arc-sql-enterprise-lab.ps1`
- Test: `scripts/deploy-arc-sql-enterprise-lab.ps1`

- [ ] **Step 1: Write the failing test**

Create a no-dependency PowerShell test that reads the deployment script, parses it with `System.Management.Automation.Language.Parser`, and asserts all required literal safety and licensing markers:

```powershell
$scriptPath = Join-Path $PSScriptRoot "..\deploy-arc-sql-enterprise-lab.ps1"
if (-not (Test-Path $scriptPath)) { throw "Deployment script does not exist: $scriptPath" }
$content = Get-Content $scriptPath -Raw
$required = @(
    '[switch]$AcceptUnsupportedLab',
    'MicrosoftSQLServer:sql2022-ws2022:enterprise-gen2:latest',
    '--license-type AHUB',
    '"LicenseType":"Paid"',
    'MSFT_ARC_TEST',
    '169.254.169.254',
    '169.254.169.253'
)
foreach ($marker in $required) {
    if (-not $content.Contains($marker)) { throw "Missing marker: $marker" }
}
if ($content.Contains('SQL2022-SSEI-Eval.exe')) { throw 'Evaluation media download must not be present.' }
$tokens = $null; $errors = $null
[System.Management.Automation.Language.Parser]::ParseFile($scriptPath, [ref]$tokens, [ref]$errors) | Out-Null
if ($errors.Count) { throw ($errors | Out-String) }
Write-Host 'Deployment contract tests: PASS'
```

- [ ] **Step 2: Run test to verify it fails**

Run: `powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File scripts/tests/test-deploy-arc-sql-enterprise-lab.ps1`

Expected: failure stating that the deployment script does not exist.

- [ ] **Step 3: Commit the red test**

Run: `git add scripts/tests/test-deploy-arc-sql-enterprise-lab.ps1 && git commit -m "test: define Arc SQL Enterprise lab contract"`

### Task 2: Implement guarded Enterprise deployment

**Files:**
- Create: `scripts/deploy-arc-sql-enterprise-lab.ps1`
- Test: `scripts/tests/test-deploy-arc-sql-enterprise-lab.ps1`

- [ ] **Step 1: Implement parameters and Azure CLI guards**

Add parameters with these exact defaults and constraints:

```powershell
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
```

Implement `Assert-Az`, `Assert-AzSuccess`, `Test-Vm`, `Invoke-InGuest`, `Open-AllInbound`, and `Remove-Lab`. Every mutating CLI call must check `$LASTEXITCODE`. Require `-AcceptUnsupportedLab` for deployment but allow cleanup without it.

- [ ] **Step 2: Implement validated VM creation**

Validate the exact image with `az vm image show` and the VM SKU with `az vm list-skus`. Create a generated lab password only for a new VM. Create the VM with:

```powershell
az vm create --resource-group $ResourceGroup --name $VmName `
    --location $Location `
    --image 'MicrosoftSQLServer:sql2022-ws2022:enterprise-gen2:latest' `
    --size $VmSize --admin-username $AdminUser --admin-password $AdminPassword `
    --public-ip-sku Standard --nsg-rule NONE -o none
```

If the VM already exists, compare publisher, offer, and SKU and reject mismatches.

- [ ] **Step 3: Implement SQL IaaS AHUB registration**

Register `Microsoft.SqlVirtualMachine`. If `az sql vm show` succeeds, run `az sql vm update --license-type AHUB`; otherwise run `az sql vm create --license-type AHUB`. Fail unless the resulting `sqlServerLicenseType` is `AHUB`.

- [ ] **Step 4: Implement Arc preparation and onboarding**

Use VM Run Command to set `MSFT_ARC_TEST`, disable Azure Guest Agent startup without stopping it, and idempotently create both IMDS firewall rules. Create a resource-group-scoped `Azure Connected Machine Onboarding` service principal, install the Connected Machine agent, and connect to Southeast Asia.

- [ ] **Step 5: Install Arc SQL with Paid license and reboot**

Create `WindowsAgent.SqlServer` with settings exactly equivalent to:

```json
{"SqlManagement":{"IsEnabled":true},"LicenseType":"Paid","ExcludedSqlInstances":[]}
```

Enable automatic extension upgrade, reboot after extension creation, and print VM, Azure SQL VM, Arc machine, Arc SQL extension, and SQL instance summary fields.

- [ ] **Step 6: Run contract test to verify it passes**

Run: `powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File scripts/tests/test-deploy-arc-sql-enterprise-lab.ps1`

Expected: `Deployment contract tests: PASS`.

- [ ] **Step 7: Commit implementation**

Run: `git add scripts/deploy-arc-sql-enterprise-lab.ps1 && git commit -m "feat: deploy Arc SQL Enterprise evaluation lab"`

### Task 3: Verify documentation and deployment preflight

**Files:**
- Create: `docs/superpowers/specs/2026-07-21-arc-sql-enterprise-azure-vm-lab-design.md`
- Create: `docs/superpowers/plans/2026-07-21-arc-sql-enterprise-azure-vm-lab.md`

- [ ] **Step 1: Parse all PowerShell scripts**

Run a PowerShell parser over `scripts/**/*.ps1` and fail on any syntax error.

Expected: zero parser errors.

- [ ] **Step 2: Run Azure read-only preflight**

Verify account authentication, image availability, `Standard_D4s_v5` availability without restrictions, at least four DSv5 and regional vCPUs remaining, and absence or compatible identity of `rg-arc-eval-ent/arc-sql-ent`.

Expected: all checks pass before any resource creation.

- [ ] **Step 3: Commit design and plan**

Run: `git add docs/superpowers && git commit -m "docs: specify Arc SQL Enterprise Azure VM lab"`

### Task 4: Deploy and validate Azure resources

**Files:**
- Execute: `scripts/deploy-arc-sql-enterprise-lab.ps1`

- [ ] **Step 1: Execute approved deployment**

Run:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File scripts/deploy-arc-sql-enterprise-lab.ps1 -AcceptUnsupportedLab
```

Expected: resource creation, AHUB registration, Arc connection, Arc SQL extension creation, reboot, and a deployment summary.

- [ ] **Step 2: Validate control-plane state**

Use Azure CLI to assert:

- VM exists and returns to `VM running`.
- SQL virtual machine license is `AHUB`.
- Connected machine status is `Connected`.
- `WindowsAgent.SqlServer` provisioning state is `Succeeded` and setting license type is `Paid`.
- Arc SQL resource reports Enterprise edition after discovery completes.

- [ ] **Step 3: Record actual results**

Report resource names, regions, states, public IP, generated credential location, any delayed discovery state, and the exact cleanup invocation. Do not repeat secrets in the final response.
