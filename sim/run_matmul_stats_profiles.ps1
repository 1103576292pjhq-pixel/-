param(
  [int]$M = 4096,
  [int]$N = 4096,
  [int]$K = 4096,
  [int]$Samples = 2048,
  [int[]]$Seeds = @(20260423, 20260503, 20260504),
  [string]$OutFile = ""
)

$ErrorActionPreference = "Stop"

$workdir = Split-Path -Parent $PSScriptRoot
$reportDir = Join-Path $workdir "reports"
if (-not $OutFile) {
  $OutFile = Join-Path $reportDir ("matmul_stats_{0}x{1}x{2}_profiles.json" -f $M, $N, $K)
}

$profiles = @(
  [ordered]@{
    name = "finite_exp8"
    description = "finite-only exponent range [-8, 8]"
    tag = ""
    allow_nonfinite = $false
    scale_exp_min = -8
    scale_exp_max = 8
  },
  [ordered]@{
    name = "finite_exp32"
    description = "finite-only exponent range [-32, 32]"
    tag = "finite_exp32"
    allow_nonfinite = $false
    scale_exp_min = -32
    scale_exp_max = 32
  },
  [ordered]@{
    name = "finite_exp64"
    description = "finite-only exponent range [-64, 64]"
    tag = "finite_exp64"
    allow_nonfinite = $false
    scale_exp_min = -64
    scale_exp_max = 64
  }
)

$profileRuns = @()
foreach ($profile in $profiles) {
  $sweepScript = Join-Path $workdir "sim\\run_matmul_stats_sweep.ps1"
  if ($profile.allow_nonfinite) {
    & $sweepScript `
      -M $M `
      -N $N `
      -K $K `
      -Samples $Samples `
      -Seeds $Seeds `
      -AllowNonFinite `
      -Tag $profile.tag | Out-Null
  } else {
    if ($profile.tag) {
      & $sweepScript `
        -M $M `
        -N $N `
        -K $K `
        -Samples $Samples `
        -Seeds $Seeds `
        -ScaleExpMin $profile.scale_exp_min `
        -ScaleExpMax $profile.scale_exp_max `
        -Tag $profile.tag | Out-Null
    } else {
      & $sweepScript `
        -M $M `
        -N $N `
        -K $K `
        -Samples $Samples `
        -Seeds $Seeds `
        -ScaleExpMin $profile.scale_exp_min `
        -ScaleExpMax $profile.scale_exp_max | Out-Null
    }
  }

  $suffix = if ($profile.tag) { "_$($profile.tag)" } elseif ($profile.allow_nonfinite) { "_mixed_nonfinite" } else { "" }
  $summaryFile = Join-Path $reportDir ("matmul_stats_{0}x{1}x{2}{3}_sweep.json" -f $M, $N, $K, $suffix)
  $summary = Get-Content $summaryFile -Raw | ConvertFrom-Json
  $profileRuns += [ordered]@{
    name = $profile.name
    description = $profile.description
    summary_file = [IO.Path]::GetFileName($summaryFile)
    finite_only = [bool]$summary.finite_only
    scale_exp_min = $summary.scale_exp_min
    scale_exp_max = $summary.scale_exp_max
    total_finite_count = [int]$summary.total_finite_count
    total_inf_count = [int]$summary.total_inf_count
    total_nan_count = [int]$summary.total_nan_count
    total_matched_nonfinite_count = [int]$summary.total_matched_nonfinite_count
    total_mismatched_nonfinite_count = [int]$summary.total_mismatched_nonfinite_count
    mean_of_mean_abs_error = $summary.mean_of_mean_abs_error
    mean_of_mean_rel_error = $summary.mean_of_mean_rel_error
    max_of_max_abs_error = $summary.max_of_max_abs_error
    max_of_max_rel_error = $summary.max_of_max_rel_error
    worst_seed_by_max_abs_error = $summary.worst_seed_by_max_abs_error
    worst_seed_by_max_rel_error = $summary.worst_seed_by_max_rel_error
  }
}

$summary = [ordered]@{
  kind = "matmul_sampled_stats_profile_sweep"
  m = $M
  n = $N
  k = $K
  samples = $Samples
  seeds = $Seeds
  profile_count = $profileRuns.Count
  profiles = $profileRuns
}

$summary | ConvertTo-Json -Depth 6 | Set-Content $OutFile -Encoding utf8
Get-Content $OutFile
