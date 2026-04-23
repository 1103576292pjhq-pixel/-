param(
  [int]$M = 4096,
  [int]$N = 4096,
  [int]$K = 4096,
  [int]$Samples = 2048,
  [int]$Seed = 20260423,
  [int]$ScaleExpMin = -8,
  [int]$ScaleExpMax = 8,
  [string]$OutFile = ""
)

$ErrorActionPreference = "Stop"

$workdir = Split-Path -Parent $PSScriptRoot
if (-not $OutFile) {
  $OutFile = Join-Path $workdir ("reports\\matmul_stats_{0}x{1}x{2}.json" -f $M, $N, $K)
}

python (Join-Path $workdir "tools\\mx_ref.py") `
  --report-matmul-stats `
  --m $M `
  --n $N `
  --k $K `
  --samples $Samples `
  --seed $Seed `
  --finite-only `
  --scale-exp-min $ScaleExpMin `
  --scale-exp-max $ScaleExpMax `
  --summary-out $OutFile
