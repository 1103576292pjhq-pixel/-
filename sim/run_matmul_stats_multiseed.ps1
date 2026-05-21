param(
  [string[]]$Seeds = @("20260508", "20260509", "20260510"),
  [int]$Samples = 256,
  [int]$M = 4096,
  [int]$N = 4096,
  [int]$K = 4096,
  [ValidateSet("baseline", "narrow-scale", "wide-scale")]
  [string]$PrecisionProfile = "baseline",
  [string]$Out = "",
  [double]$MeanRelErrorLimit = 1.0e-5,
  [double]$MaxRelErrorLimit = 1.0e-3,
  [switch]$NoThresholdCheck
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$ReportDir = Join-Path $Root "reports"
New-Item -ItemType Directory -Force -Path $ReportDir | Out-Null

if ([string]::IsNullOrWhiteSpace($Out)) {
  $ProfileSuffix = $PrecisionProfile -replace "[^A-Za-z0-9_-]", "_"
  if ($PrecisionProfile -eq "baseline") {
    $OutPath = Join-Path $ReportDir ("matmul_stats_{0}x{1}x{2}_multiseed.json" -f $M, $N, $K)
  } else {
    $OutPath = Join-Path $ReportDir ("matmul_stats_{0}x{1}x{2}_{3}_multiseed.json" -f $M, $N, $K, $ProfileSuffix)
  }
} elseif ([System.IO.Path]::IsPathRooted($Out)) {
  $OutPath = $Out
} else {
  $OutPath = Join-Path $Root $Out
}

$OutParent = Split-Path -Parent $OutPath
if (-not [string]::IsNullOrWhiteSpace($OutParent)) {
  New-Item -ItemType Directory -Force -Path $OutParent | Out-Null
}

$SeedList = @()
foreach ($Item in $Seeds) {
  foreach ($Part in ($Item -split ",")) {
    $Trimmed = $Part.Trim()
    if ($Trimmed.Length -gt 0) {
      $SeedList += [int]$Trimmed
    }
  }
}

if ($SeedList.Count -eq 0) {
  throw "at least one seed is required"
}

if ($Samples -le 0) {
  throw "Samples must be positive"
}

if (($K % 32) -ne 0) {
  throw "K must be a multiple of 32"
}

$PerSeed = @()
$TotalSamples = 0
$WeightedAbsSum = 0.0
$WeightedRelSum = 0.0
$MaxAbsError = -1.0
$MaxAbsSeed = $null
$MaxRelError = -1.0
$MaxRelSeed = $null
$WorstByRel = $null

foreach ($Seed in $SeedList) {
  $SeedOut = [System.IO.Path]::GetTempFileName()
  try {
    python (Join-Path $Root "tools\mx_ref.py") `
      --report-matmul-stats `
      --out-dir $SeedOut `
      --m $M `
      --n $N `
      --k $K `
      --samples $Samples `
      --seed $Seed `
      --precision-profile $PrecisionProfile

    if ($LASTEXITCODE -ne 0) {
      throw ("matmul stats failed for seed {0}" -f $Seed)
    }

    $Stats = Get-Content -Raw $SeedOut | ConvertFrom-Json
    $PerSeed += $Stats

    $SeedSamples = [int]$Stats.samples
    $TotalSamples += $SeedSamples
    $WeightedAbsSum += ([double]$Stats.mean_abs_error * $SeedSamples)
    $WeightedRelSum += ([double]$Stats.mean_rel_error * $SeedSamples)

    if ([double]$Stats.max_abs_error -gt $MaxAbsError) {
      $MaxAbsError = [double]$Stats.max_abs_error
      $MaxAbsSeed = [int]$Stats.seed
    }

    if ([double]$Stats.max_rel_error -gt $MaxRelError) {
      $MaxRelError = [double]$Stats.max_rel_error
      $MaxRelSeed = [int]$Stats.seed
      $WorstByRel = $Stats.worst
    }
  } finally {
    Remove-Item -LiteralPath $SeedOut -ErrorAction SilentlyContinue
  }
}

$MeanAbsError = $WeightedAbsSum / $TotalSamples
$MeanRelError = $WeightedRelSum / $TotalSamples

$ThresholdFailures = @()
if (-not $NoThresholdCheck.IsPresent) {
  if ($MeanRelError -gt $MeanRelErrorLimit) {
    $ThresholdFailures += ("mean_rel_error {0} exceeded limit {1}" -f $MeanRelError, $MeanRelErrorLimit)
  }
  if ($MaxRelError -gt $MaxRelErrorLimit) {
    $ThresholdFailures += ("max_rel_error {0} exceeded limit {1}" -f $MaxRelError, $MaxRelErrorLimit)
  }
}

$ThresholdStatus = "not_checked"
if (-not $NoThresholdCheck.IsPresent) {
  if ($ThresholdFailures.Count -eq 0) {
    $ThresholdStatus = "pass"
  } else {
    $ThresholdStatus = "fail"
  }
}

$Aggregate = [ordered]@{
  mean_abs_error = $MeanAbsError
  mean_rel_error = $MeanRelError
  max_abs_error = $MaxAbsError
  max_abs_error_seed = $MaxAbsSeed
  max_rel_error = $MaxRelError
  max_rel_error_seed = $MaxRelSeed
  worst_by_rel_error = [ordered]@{
    seed = $MaxRelSeed
    detail = $WorstByRel
  }
}

$Result = [ordered]@{
  kind = "sampled_matmul_stats_multiseed"
  generated_by = "sim/run_matmul_stats_multiseed.ps1"
  generated_at_utc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  m = $M
  n = $N
  k = $K
  k_blocks = [int]($K / 32)
  precision_profile = $PrecisionProfile
  seeds = @($SeedList)
  seed_count = $SeedList.Count
  samples_per_seed = $Samples
  total_samples = $TotalSamples
  aggregate = $Aggregate
  thresholds = [ordered]@{
    enabled = (-not $NoThresholdCheck.IsPresent)
    mean_rel_error_limit = $MeanRelErrorLimit
    max_rel_error_limit = $MaxRelErrorLimit
    status = $ThresholdStatus
    failures = @($ThresholdFailures)
  }
  per_seed = @($PerSeed)
  note = "Each seed uses tools/mx_ref.py --report-matmul-stats with sampled row/column points and the requested precision profile; this is diagnostic precision evidence, not an exhaustive matrix dump."
}

$Result | ConvertTo-Json -Depth 12 | Set-Content -Encoding ascii -Path $OutPath

if ($ThresholdStatus -eq "fail") {
  throw ("multi-seed precision thresholds failed: {0}" -f ($ThresholdFailures -join "; "))
}

Write-Host ("PASS run_matmul_stats_multiseed {0} profile={1}" -f $OutPath, $PrecisionProfile)
