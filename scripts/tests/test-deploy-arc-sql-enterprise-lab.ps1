$ErrorActionPreference = 'Stop'

$scriptPath = Join-Path $PSScriptRoot "..\deploy-arc-sql-enterprise-lab.ps1"
if (-not (Test-Path $scriptPath)) {
    throw "Deployment script does not exist: $scriptPath"
}

$content = Get-Content $scriptPath -Raw
$required = @(
    '[switch]$AcceptUnsupportedLab',
    'MicrosoftSQLServer:sql2022-ws2022:enterprise-gen2:latest',
    '--license-type AHUB',
    '"LicenseType":"Paid"',
    'MSFT_ARC_TEST',
    '169.254.169.254',
    '169.254.169.253',
    '$arcAlreadyConnected',
    'if (-not $arcAlreadyConnected)'
)

foreach ($marker in $required) {
    if (-not $content.Contains($marker)) {
        throw "Missing marker: $marker"
    }
}

if ($content.Contains('SQL2022-SSEI-Eval.exe')) {
    throw 'Evaluation media download must not be present.'
}

$ahubIndex = $content.LastIndexOf('Set-SqlVmAhub')
$prepareIndex = $content.LastIndexOf('Invoke-InGuest -ScriptText $prepare')
$extensionIndex = $content.LastIndexOf("Write-Host '>> Installing Azure extension for SQL Server")
$rebootIndex = $content.LastIndexOf('az vm restart')
if ($ahubIndex -lt 0 -or $prepareIndex -lt 0 -or
    $extensionIndex -lt 0 -or $rebootIndex -lt 0) {
    throw 'Unable to locate deployment ordering markers.'
}
if (-not ($ahubIndex -lt $prepareIndex -and
          $prepareIndex -lt $extensionIndex -and
          $extensionIndex -lt $rebootIndex)) {
    throw 'Required order is AHUB, Arc preparation, Arc SQL extension, then reboot.'
}

$tokens = $null
$errors = $null
[System.Management.Automation.Language.Parser]::ParseFile(
    $scriptPath,
    [ref]$tokens,
    [ref]$errors
) | Out-Null

if ($errors.Count) {
    throw ($errors | Out-String)
}

Write-Host 'Deployment contract tests: PASS' -ForegroundColor Green
