$ErrorActionPreference = "Stop"

$workdir = Split-Path -Parent $PSScriptRoot
$buildDir = Join-Path $workdir "sim"
$rtlIncludeDir = Join-Path $workdir "rtl"
$tbIncludeDir = Join-Path $workdir "tb"
$waveDir = Join-Path $workdir "reports\evidence\waveforms"
$logDir = Join-Path $workdir "reports\verification"
$logFile = Join-Path $logDir "waveform_smoke.log"

New-Item -ItemType Directory -Force -Path $waveDir | Out-Null
New-Item -ItemType Directory -Force -Path $logDir | Out-Null

$rtlFiles = @(
  (Join-Path $workdir "rtl\e4m3_decode.v"),
  (Join-Path $workdir "rtl\e8m0_scale_decode.v"),
  (Join-Path $workdir "rtl\fixed_to_fp32.v"),
  (Join-Path $workdir "rtl\fp32_add_rne.v"),
  (Join-Path $workdir "rtl\llmt_col.v"),
  (Join-Path $workdir "rtl\mx_array_32x16.v")
)

function Invoke-WaveformTest {
  param(
    [Parameter(Mandatory = $true)][string]$Name,
    [Parameter(Mandatory = $true)][string]$Testbench
  )

  $outFile = Join-Path $buildDir "$Name.vvp"
  $vcdFile = Join-Path $waveDir "$Name.vcd"
  & iverilog -g2001 -DDUMP_VCD -I $rtlIncludeDir -I $tbIncludeDir -o $outFile @rtlFiles $Testbench
  & vvp $outFile "+VCD_FILE=$vcdFile"
  if (!(Test-Path $vcdFile)) {
    throw "Missing waveform output: $vcdFile"
  }
}

$previousLocation = Get-Location
try {
  Set-Location $workdir
  Start-Transcript -Path $logFile -Force | Out-Null
  Invoke-WaveformTest -Name "tb_llmt_col_smoke_wave" -Testbench (Join-Path $workdir "tb\tb_llmt_col_smoke.v")
  Invoke-WaveformTest -Name "tb_llmt_col_back_to_back_wave" -Testbench (Join-Path $workdir "tb\tb_llmt_col_back_to_back.v")
  Invoke-WaveformTest -Name "tb_mx_array_smoke_wave" -Testbench (Join-Path $workdir "tb\tb_mx_array_smoke.v")
  Write-Host "PASS: waveform smoke VCD files generated under $waveDir"
}
finally {
  try { Stop-Transcript | Out-Null } catch { }
  Set-Location $previousLocation
}
