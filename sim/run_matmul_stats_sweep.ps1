param(
  [int]$M = 4096,
  [int]$N = 4096,
  [int]$K = 4096,
  [int]$Samples = 2048,
  [int[]]$Seeds = @(20260423, 20260503, 20260504),
  [int]$ScaleExpMin = -8,
  [int]$ScaleExpMax = 8,
  [switch]$AllowNonFinite,
  [string]$Tag = "",
  [string]$OutFile = ""
)

$ErrorActionPreference = "Stop"

$workdir = Split-Path -Parent $PSScriptRoot
$reportDir = Join-Path $workdir "reports"
$suffix = ""
if ($Tag) {
  $suffix = "_$Tag"
} elseif ($AllowNonFinite) {
  $suffix = "_mixed_nonfinite"
}
if (-not $OutFile) {
  $OutFile = Join-Path $reportDir ("matmul_stats_{0}x{1}x{2}{3}_sweep.json" -f $M, $N, $K, $suffix)
}

$runs = @()
foreach ($Seed in $Seeds) {
  $seedFile = Join-Path $reportDir ("matmul_stats_{0}x{1}x{2}{3}_seed{4}.json" -f $M, $N, $K, $suffix, $Seed)
  $pythonArgs = @(
    (Join-Path $workdir "tools\\mx_ref.py"),
    "--report-matmul-stats",
    "--m", "$M",
    "--n", "$N",
    "--k", "$K",
    "--samples", "$Samples",
    "--seed", "$Seed",
    "--summary-out", "$seedFile"
  )
  if (-not $AllowNonFinite) {
    $pythonArgs += @(
      "--finite-only",
      "--scale-exp-min", "$ScaleExpMin",
      "--scale-exp-max", "$ScaleExpMax"
    )
  }
  & python @pythonArgs | Out-Null

  $run = Get-Content $seedFile -Raw | ConvertFrom-Json
  $runs += [pscustomobject]@{
    seed = [int]$run.seed
    samples = [int]$run.samples
    finite_count = [int]$run.finite_count
    inf_count = [int]$run.inf_count
    nan_count = [int]$run.nan_count
    matched_nonfinite_count = [int]$run.matched_nonfinite_count
    mismatched_nonfinite_count = [int]$run.mismatched_nonfinite_count
    mean_abs_error = if ($null -ne $run.mean_abs_error) { [double]$run.mean_abs_error } else { $null }
    mean_rel_error = if ($null -ne $run.mean_rel_error) { [double]$run.mean_rel_error } else { $null }
    max_abs_error = if ($null -ne $run.max_abs_error) { [double]$run.max_abs_error } else { $null }
    max_rel_error = if ($null -ne $run.max_rel_error) { [double]$run.max_rel_error } else { $null }
    project_checksum_xor = [string]$run.project_checksum_xor
  }
}

function Get-NumericSeries {
  param(
    [Parameter(Mandatory = $true)][object[]]$Items,
    [Parameter(Mandatory = $true)][string]$Property
  )

  $values = @()
  foreach ($Item in $Items) {
    $value = $Item.$Property
    if ($null -ne $value) {
      $values += [double]$value
    }
  }
  return $values
}

$meanAbsValues = Get-NumericSeries -Items $runs -Property "mean_abs_error"
$meanRelValues = Get-NumericSeries -Items $runs -Property "mean_rel_error"
$maxAbsValues = Get-NumericSeries -Items $runs -Property "max_abs_error"
$maxRelValues = Get-NumericSeries -Items $runs -Property "max_rel_error"
$worstAbsRun = $runs | Where-Object { $null -ne $_.max_abs_error } | Sort-Object max_abs_error -Descending | Select-Object -First 1
$worstRelRun = $runs | Where-Object { $null -ne $_.max_rel_error } | Sort-Object max_rel_error -Descending | Select-Object -First 1
$summary = [ordered]@{
  kind = "matmul_sampled_stats_sweep"
  m = $M
  n = $N
  k = $K
  finite_only = (-not $AllowNonFinite)
  samples = $Samples
  seeds = $Seeds
  tag = if ($Tag) { $Tag } elseif ($AllowNonFinite) { "mixed_nonfinite" } else { $null }
  scale_exp_min = if ($AllowNonFinite) { $null } else { $ScaleExpMin }
  scale_exp_max = if ($AllowNonFinite) { $null } else { $ScaleExpMax }
  run_count = $runs.Count
  total_finite_count = ($runs | Measure-Object -Property finite_count -Sum).Sum
  total_inf_count = ($runs | Measure-Object -Property inf_count -Sum).Sum
  total_nan_count = ($runs | Measure-Object -Property nan_count -Sum).Sum
  total_matched_nonfinite_count = ($runs | Measure-Object -Property matched_nonfinite_count -Sum).Sum
  total_mismatched_nonfinite_count = ($runs | Measure-Object -Property mismatched_nonfinite_count -Sum).Sum
  mean_of_mean_abs_error = if ($meanAbsValues.Count) { ($meanAbsValues | Measure-Object -Average).Average } else { $null }
  mean_of_mean_rel_error = if ($meanRelValues.Count) { ($meanRelValues | Measure-Object -Average).Average } else { $null }
  max_of_max_abs_error = if ($maxAbsValues.Count) { ($maxAbsValues | Measure-Object -Maximum).Maximum } else { $null }
  max_of_max_rel_error = if ($maxRelValues.Count) { ($maxRelValues | Measure-Object -Maximum).Maximum } else { $null }
  worst_seed_by_max_abs_error = [ordered]@{
    seed = if ($worstAbsRun) { $worstAbsRun.seed } else { $null }
    max_abs_error = if ($worstAbsRun) { $worstAbsRun.max_abs_error } else { $null }
  }
  worst_seed_by_max_rel_error = [ordered]@{
    seed = if ($worstRelRun) { $worstRelRun.seed } else { $null }
    max_rel_error = if ($worstRelRun) { $worstRelRun.max_rel_error } else { $null }
  }
  per_seed = $runs
}

$summary | ConvertTo-Json -Depth 6 | Set-Content $OutFile -Encoding utf8
Get-Content $OutFile
