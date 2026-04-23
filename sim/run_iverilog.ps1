$ErrorActionPreference = "Stop"

$workdir = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $workdir "sim"
$rtlIncludeDir = Join-Path $workdir "rtl"
$tbIncludeDir = Join-Path $workdir "tb"
$rtlFiles = @(
  (Join-Path $workdir "rtl\\e4m3_decode.v"),
  (Join-Path $workdir "rtl\\e8m0_scale_decode.v"),
  (Join-Path $workdir "rtl\\fixed_to_fp32.v"),
  (Join-Path $workdir "rtl\\fp32_add_rne.v"),
  (Join-Path $workdir "rtl\\llmt_col.v"),
  (Join-Path $workdir "rtl\\mx_array_32x16.v")
)

function Invoke-IverilogTest {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Testbench,
    [string[]]$Defines = @()
  )

  $outFile = Join-Path $buildDir "$Name.vvp"
  & iverilog -g2001 -I $rtlIncludeDir -I $tbIncludeDir @Defines -o $outFile @rtlFiles $Testbench
  & vvp $outFile
}

Invoke-IverilogTest -Name "tb_llmt_col_smoke" -Testbench (Join-Path $workdir "tb\\tb_llmt_col_smoke.v")
Invoke-IverilogTest -Name "tb_llmt_col_back_to_back" -Testbench (Join-Path $workdir "tb\\tb_llmt_col_back_to_back.v")
Invoke-IverilogTest -Name "tb_llmt_col_corner" -Testbench (Join-Path $workdir "tb\\tb_llmt_col_corner.v")
Invoke-IverilogTest -Name "tb_mx_array_smoke" -Testbench (Join-Path $workdir "tb\\tb_mx_array_smoke.v")
Invoke-IverilogTest `
  -Name "tb_mx_array_dataset" `
  -Testbench (Join-Path $workdir "tb\\tb_mx_array_dataset.v") `
  -Defines @(
    "-DTB_M=4",
    "-DTB_N=16",
    "-DTB_K_BLOCKS=2"
  )
Invoke-IverilogTest `
  -Name "tb_mx_array_dataset_3x18x64_nonfinite" `
  -Testbench (Join-Path $workdir "tb\\tb_mx_array_dataset_3x18x64_nonfinite.v")
Invoke-IverilogTest `
  -Name "tb_mx_array_dataset_8x32x128" `
  -Testbench (Join-Path $workdir "tb\\tb_mx_array_dataset_8x32x128.v")
Invoke-IverilogTest `
  -Name "tb_mx_array_dataset_5x20x96" `
  -Testbench (Join-Path $workdir "tb\\tb_mx_array_dataset_5x20x96.v")
