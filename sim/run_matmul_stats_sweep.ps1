param(
  [int]$M = 4096,
  [int]$N = 4096,
  [int]$K = 4096,
  [int]$Samples = 2048,
  [int[]]$Seeds = @(20260423, 20260503, 20260504),
  [int]$ScaleExpMin = -8,
  [int]$ScaleExpMax = 8,
  [string]$OutFile = ""
)

$ErrorActionPreference = "Stop"

$workdir = Split-Path -Parent $PSScriptRoot
$reportDir = Join-Path $workdir "reports"
if (-not $OutFile) {
  $OutFile = Join-Path $reportDir ("matmul_stats_{0}x{1}x{2}_sweep.json" -f $M, $N, $K)
}

$runs = @()
foreach ($Seed in $Seeds) {
  $seedFile = Join-Path $reportDir ("matmul_stats_{0}x{1}x{2}_seed{3}.json" -f $M, $N, $K, $Seed)
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
    --summary-out $seedFile | Out-Null

  $run = Get-Content $seedFile -Raw | ConvertFrom-Json
  $runs += [pscustomobject]@{
    seed = [int]$run.seed
    samples = [int]$run.samples
    finite_count = [int]$run.finite_count
    inf_count = [int]$run.inf_count
    nan_count = [int]$run.nan_count
    mean_abs_error = [double]$run.mean_abs_error
    mean_rel_error = [double]$run.mean_rel_error
    max_abs_error = [double]$run.max_abs_error
    max_rel_error = [double]$run.max_rel_error
    project_checksum_xor = [string]$run.project_checksum_xor
  }
}

$worstAbsRun = $runs | Sort-Object max_abs_error -Descending | Select-Object -First 1
$worstRelRun = $runs | Sort-Object max_rel_error -Descending | Select-Object -First 1
$summary = [ordered]@{
  kind = "matmul_sampled_stats_sweep"
  m = $M
  n = $N
  k = $K
  finite_only = $true
  samples = $Samples
  seeds = $Seeds
  scale_exp_min = $ScaleExpMin
  scale_exp_max = $ScaleExpMax
  run_count = $runs.Count
  mean_of_mean_abs_error = ($runs | Measure-Object -Property mean_abs_error -Average).Average
  mean_of_mean_rel_error = ($runs | Measure-Object -Property mean_rel_error -Average).Average
  max_of_max_abs_error = ($runs | Measure-Object -Property max_abs_error -Maximum).Maximum
  max_of_max_rel_error = ($runs | Measure-Object -Property max_rel_error -Maximum).Maximum
  worst_seed_by_max_abs_error = [ordered]@{
    seed = $worstAbsRun.seed
    max_abs_error = $worstAbsRun.max_abs_error
  }
  worst_seed_by_max_rel_error = [ordered]@{
    seed = $worstRelRun.seed
    max_rel_error = $worstRelRun.max_rel_error
  }
  per_seed = $runs
}

$summary | ConvertTo-Json -Depth 6 | Set-Content $OutFile -Encoding utf8
Get-Content $OutFile
