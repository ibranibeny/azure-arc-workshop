# Lab 04 Run Guidance Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Put a complete, copyable clone-to-cleanup quick-start near the top of Lab 04 and publish it to GitHub Pages.

**Architecture:** Add a small PowerShell content-contract test, then replace the buried **Get the script** section with a prominent **Run this lab** tutorial immediately after **Lab details**. Keep the existing architecture explanation and block-by-block walkthrough intact, and validate the rendered GitHub Pages result after publishing.

**Tech Stack:** Markdown, Jekyll/Minimal Mistakes, Liquid/Kramdown, PowerShell, GitHub Pages, GitHub CLI.

---

### Task 1: Define the Lab 04 run-guidance contract

**Files:**
- Create: `scripts/tests/test-lab04-run-guidance.ps1`
- Test: `_labs/04-simulate-vm-sql-arc.md`

- [ ] **Step 1: Write the failing content-contract test**

Create `scripts/tests/test-lab04-run-guidance.ps1` with:

```powershell
$ErrorActionPreference = 'Stop'

$pagePath = Join-Path $PSScriptRoot '..\..\_labs\04-simulate-vm-sql-arc.md'
$content = Get-Content $pagePath -Raw

$required = @(
    '## Run this lab',
    '### Step 1 — Clone the repository',
    'git clone https://github.com/ibranibeny/azure-arc-workshop.git',
    'Set-Location .\azure-arc-workshop\scripts',
    '### Step 2 — Sign in and select the subscription',
    'az login',
    "az account set --subscription (Read-Host 'Enter subscription ID or name')",
    '### Step 3 — Choose one deployment path',
    '.\evaluate-arc-on-azure-vm.ps1 -ResourceGroup rg-arc-eval',
    '.\deploy-arc-sql-enterprise-lab.ps1 -AcceptUnsupportedLab',
    '### Step 4 — Verify the deployment',
    'az connectedmachine show',
    'WindowsAgent.SqlServer',
    'Microsoft.AzureArcData/sqlServerInstances',
    '### Step 5 — Clean up',
    '.\evaluate-arc-on-azure-vm.ps1 -ResourceGroup rg-arc-eval -Cleanup',
    '.\deploy-arc-sql-enterprise-lab.ps1 -Cleanup'
)

foreach ($marker in $required) {
    if (-not $content.Contains($marker)) {
        throw "Missing Lab 04 run-guidance marker: $marker"
    }
}

$runIndex = $content.IndexOf('## Run this lab')
$whyIndex = $content.IndexOf('## Why this matters')
if ($runIndex -lt 0 -or $whyIndex -lt 0 -or $runIndex -gt $whyIndex) {
    throw 'Run this lab must appear before Why this matters.'
}

if ($content.Contains('-OpenAllInboundPorts')) {
    throw 'The quick-start must not enable all inbound ports by default.'
}

Write-Host 'Lab 04 run-guidance contract: PASS' -ForegroundColor Green
```

- [ ] **Step 2: Run the test and verify RED**

Run:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File scripts/tests/test-lab04-run-guidance.ps1
```

Expected: FAIL with `Missing Lab 04 run-guidance marker: ## Run this lab`.

- [ ] **Step 3: Commit the failing contract**

Run:

```bash
git add scripts/tests/test-lab04-run-guidance.ps1
git commit -m "test: define Lab 04 run guidance contract"
```

### Task 2: Add the prominent clone-to-cleanup tutorial

**Files:**
- Modify: `_labs/04-simulate-vm-sql-arc.md`
- Test: `scripts/tests/test-lab04-run-guidance.ps1`

- [ ] **Step 1: Add a top-page run button**

After the Lab details table, add:

```markdown
[Run the lab](#run-this-lab){: .btn .btn--primary .btn--large}
```

- [ ] **Step 2: Add the numbered quick-start before Why this matters**

Add a `## Run this lab` section with these subsections and complete commands:

````markdown
## Run this lab

Follow these steps to clone, authenticate, deploy, verify, and clean up the workshop.

### Step 1 — Clone the repository

```powershell
git clone https://github.com/ibranibeny/azure-arc-workshop.git
Set-Location .\azure-arc-workshop\scripts
```

### Step 2 — Sign in and select the subscription

```powershell
az login
az account list --output table
az account set --subscription (Read-Host 'Enter subscription ID or name')
az account show --output table
```

### Step 3 — Choose one deployment path

Run only one of the following paths.

**Evaluation inventory:**

```powershell
.\evaluate-arc-on-azure-vm.ps1 -ResourceGroup rg-arc-eval
```

**Enterprise/BPA-eligible:**

```powershell
.\deploy-arc-sql-enterprise-lab.ps1 -AcceptUnsupportedLab
```

The Enterprise path requires qualifying SQL Server Enterprise licensing with Software Assurance or a SQL Server subscription. It configures Azure SQL VM as `AHUB` and Arc SQL as `Paid`. The Azure VM simulation is evaluation-only and unsupported for production.
{: .notice--danger}

### Step 4 — Verify the deployment

```powershell
$ResourceGroup = 'rg-arc-eval-ent'
$MachineName = 'arc-sql-ent'

az vm show -d --resource-group $ResourceGroup --name $MachineName `
  --query '{provisioningState:provisioningState,powerState:powerState}' --output table

az connectedmachine show --resource-group $ResourceGroup --name $MachineName `
  --query '{status:status,location:location,provisioningState:provisioningState}' --output table

az connectedmachine extension show --resource-group $ResourceGroup `
  --machine-name $MachineName --name WindowsAgent.SqlServer `
  --query '{state:properties.provisioningState,license:properties.settings.LicenseType}' --output table

az resource list --resource-group $ResourceGroup `
  --resource-type Microsoft.AzureArcData/sqlServerInstances `
  --query '[].{name:name,edition:properties.edition,license:properties.licenseType,status:properties.status}' --output table
```

For the Evaluation path, use `rg-arc-eval` and `arc-eval-sql`. BPA is not available with `LicenseOnly`. For the Enterprise path, BPA becomes eligible after a Log Analytics workspace is configured and BPA is enabled.

### Step 5 — Clean up

Run the command matching the path selected in Step 3:

```powershell
# Evaluation path
.\evaluate-arc-on-azure-vm.ps1 -ResourceGroup rg-arc-eval -Cleanup

# Enterprise path
.\deploy-arc-sql-enterprise-lab.ps1 -Cleanup
```
````

- [ ] **Step 3: Remove the duplicated buried run instructions**

Remove the existing `## Get the script` and `### Optional Enterprise path for Best Practices Assessment` execution blocks. Preserve their licensing and BPA facts in the new quick-start. Leave `## Why this matters`, `## Architecture of this lab`, prerequisites, and the detailed walkthrough unchanged.

- [ ] **Step 4: Run the test and verify GREEN**

Run:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File scripts/tests/test-lab04-run-guidance.ps1
```

Expected: `Lab 04 run-guidance contract: PASS`.

- [ ] **Step 5: Run all PowerShell checks**

Run:

```powershell
powershell.exe -NoLogo -NoProfile -ExecutionPolicy Bypass -File scripts/tests/test-deploy-arc-sql-enterprise-lab.ps1
```

Expected: `Deployment contract tests: PASS`.

Parse every file below `scripts` with `System.Management.Automation.Language.Parser`; expected result is zero syntax errors.

- [ ] **Step 6: Commit the tutorial**

Run:

```bash
git add _labs/04-simulate-vm-sql-arc.md scripts/tests/test-lab04-run-guidance.ps1
git commit -m "docs: add prominent Lab 04 run instructions"
```

### Task 3: Publish and validate GitHub Pages

**Files:**
- Publish: `_labs/04-simulate-vm-sql-arc.md`

- [ ] **Step 1: Push main**

Run:

```bash
git push origin main
```

Expected: the new commit is pushed to `ibranibeny/azure-arc-workshop`.

- [ ] **Step 2: Verify the Pages build**

Run:

```bash
gh api repos/ibranibeny/azure-arc-workshop/pages/builds/latest \
  --jq '{status:.status,commit:.commit,error:.error.message}'
```

Expected: `status` is `built`, `commit` is the new documentation commit, and `error` is empty.

- [ ] **Step 3: Validate the rendered page**

Open:

```text
https://ibranibeny.github.io/azure-arc-workshop/labs/04-simulate-vm-sql-arc/
```

Confirm the rendered page contains, in order:

1. **Run the lab** button.
2. **Run this lab** before **Why this matters**.
3. Clone and subscription commands.
4. Evaluation and Enterprise deployment choices.
5. Verification commands.
6. Matching cleanup commands.

- [ ] **Step 4: Verify the repository is clean**

Run:

```bash
git status --short
```

Expected: no output.
