$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ReportDir = Join-Path $Root "reports"
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null

$Out = Join-Path $ReportDir "matmul_stats_4096x4096x4096_sampled.json"
python (Join-Path $Root "tools\mx_ref.py") `
  --report-matmul-stats `
  --out-dir $Out `
  --m 4096 `
  --n 4096 `
  --k 4096 `
  --samples 256 `
  --seed 20260508

if ($LASTEXITCODE -ne 0) {
  throw "matmul stats failed"
}

Write-Host "PASS run_matmul_stats $Out"
