$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path

$steps = @(
  @{
    Name = "python selftest"
    File = "python"
    Args = @((Join-Path $Root "tools\mx_ref.py"), "--selftest")
  },
  @{
    Name = "iverilog regression"
    File = "powershell"
    Args = @("-ExecutionPolicy", "Bypass", "-File", (Join-Path $Root "sim\run_iverilog.ps1"))
  },
  @{
    Name = "waveform smoke"
    File = "powershell"
    Args = @("-ExecutionPolicy", "Bypass", "-File", (Join-Path $Root "sim\run_waveform_smoke.ps1"))
  },
  @{
    Name = "sampled matmul stats"
    File = "powershell"
    Args = @("-ExecutionPolicy", "Bypass", "-File", (Join-Path $Root "sim\run_matmul_stats.ps1"))
  }
)

foreach ($step in $steps) {
  Write-Host ("=== {0} ===" -f $step.Name)
  & $step.File @($step.Args)
  if ($LASTEXITCODE -ne 0) {
    throw ("step failed: {0}" -f $step.Name)
  }
}

Write-Host "PASS run_frontend_regression"
