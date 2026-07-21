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
    '169.254.169.253'
)

foreach ($marker in $required) {
    if (-not $content.Contains($marker)) {
        throw "Missing marker: $marker"
    }
}

if ($content.Contains('SQL2022-SSEI-Eval.exe')) {
    throw 'Evaluation media download must not be present.'
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
