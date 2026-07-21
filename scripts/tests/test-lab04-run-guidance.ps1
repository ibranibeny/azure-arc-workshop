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

$quickStart = $content.Substring($runIndex, $whyIndex - $runIndex)
if ($quickStart.Contains('-OpenAllInboundPorts')) {
    throw 'The quick-start must not enable all inbound ports by default.'
}

Write-Host 'Lab 04 run-guidance contract: PASS' -ForegroundColor Green
