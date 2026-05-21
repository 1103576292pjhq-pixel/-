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
  "tb/tb_fixed_to_fp32_boundary.v",
  "tb/tb_fp32_add_basic.v",
  "tb/tb_fp32_add_subnormal.v",
  "tb/tb_llmt_col_basic.v",
  "tb/tb_llmt_col_boundary.v",
  "tb/tb_mx_array_basic.v",
  "tb/tb_mx_array_col_independence.v",
  "tb/tb_mx_array_dataset_3x20x64.v",
  "tb/tb_mx_array_dataset_2x17x32_nonfinite.v",
  "tb/tb_mx_array_dataset_4x33x96_random.v"
)

foreach ($test in $Tests) {
  $name = [System.IO.Path]::GetFileNameWithoutExtension($test)
  $out = Join-Path $BuildDir "$name.vvp"
  $args = @(
    "-g2012",
    "-I", (Join-Path $Root "rtl"),
    "-I", (Join-Path $Root "tb"),
    "-o", $out
  )
  foreach ($file in $Rtl) {
    $args += (Join-Path $Root $file)
  }
  $args += (Join-Path $Root $test)

  Write-Host "BUILD $name"
  & iverilog @args
  if ($LASTEXITCODE -ne 0) {
    throw "iverilog failed for $name"
  }

  Write-Host "RUN   $name"
  & vvp $out
  if ($LASTEXITCODE -ne 0) {
    throw "vvp failed for $name"
  }
}

Write-Host "PASS run_iverilog"
