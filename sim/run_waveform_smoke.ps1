$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$BuildDir = Join-Path $Root "build"
New-Item -ItemType Directory -Force -Path $BuildDir | Out-Null

$Rtl = @(
  "rtl/fixed_to_fp32.v",
  "rtl/fp32_add_rne.v",
  "rtl/llmt_col.v",
  "rtl/mx_array_32x16.v"
)

$Tests = @(
  "tb/tb_llmt_col_basic.v",
  "tb/tb_mx_array_basic.v"
)

foreach ($test in $Tests) {
  $name = [System.IO.Path]::GetFileNameWithoutExtension($test)
  $out = Join-Path $BuildDir "$name.wave.vvp"
  $args = @(
    "-g2012",
    "-DDUMP_VCD",
    "-I", (Join-Path $Root "rtl"),
    "-I", (Join-Path $Root "tb"),
    "-o", $out
  )
  foreach ($file in $Rtl) {
    $args += (Join-Path $Root $file)
  }
  $args += (Join-Path $Root $test)

  Write-Host "BUILD WAVE $name"
  & iverilog @args
  if ($LASTEXITCODE -ne 0) {
    throw "iverilog failed for $name"
  }

  Write-Host "RUN   WAVE $name"
  & vvp $out
  if ($LASTEXITCODE -ne 0) {
    throw "vvp failed for $name"
  }
}

Write-Host "PASS run_waveform_smoke"
Write-Host "VCD files are in $BuildDir"
