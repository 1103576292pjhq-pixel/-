param(
  [string[]]$Profiles = @("baseline", "narrow-scale", "wide-scale"),
  [string[]]$Seeds = @("20260508", "20260509", "20260510"),
  [int]$Samples = 256,
  [int]$M = 4096,
  [int]$N = 4096,
  [int]$K = 4096,
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
  $OutPath = Join-Path $ReportDir ("matmul_stats_{0}x{1}x{2}_profiles.json" -f $M, $N, $K)
} elseif ([System.IO.Path]::IsPathRooted($Out)) {
  $OutPath = $Out
} else {
  $OutPath = Join-Path $Root $Out
}

$OutParent = Split-Path -Parent $OutPath
if (-not [string]::IsNullOrWhiteSpace($OutParent)) {
  New-Item -ItemType Directory -Force -Path $OutParent | Out-Null
}

$ValidProfiles = @("baseline", "narrow-scale", "wide-scale")
$ProfileList = @()
foreach ($Item in $Profiles) {
  foreach ($Part in ($Item -split ",")) {
    $Trimmed = $Part.Trim()
    if ($Trimmed.Length -gt 0) {
      if ($ValidProfiles -notcontains $Trimmed) {
        throw ("unknown precision profile '{0}'; valid profiles: {1}" -f $Trimmed, ($ValidProfiles -join ", "))
      }
      $ProfileList += $Trimmed
    }
  }
}

if ($ProfileList.Count -eq 0) {
  throw "at least one precision profile is required"
}

$ProfileResults = @()
$Failures = @()

foreach ($Profile in $ProfileList) {
  $ProfileSuffix = $Profile -replace "[^A-Za-z0-9_-]", "_"
  $ProfileOut = Join-Path $ReportDir ("matmul_stats_{0}x{1}x{2}_{3}_multiseed.json" -f $M, $N, $K, $ProfileSuffix)
  if ($Profile -eq "baseline") {
    $ProfileOut = Join-Path $ReportDir ("matmul_stats_{0}x{1}x{2}_baseline_multiseed.json" -f $M, $N, $K)
  }

  $Args = @(
    "-ExecutionPolicy", "Bypass",
    "-File", (Join-Path $Root "sim\run_matmul_stats_multiseed.ps1"),
    "-Seeds", ($Seeds -join ","),
    "-Samples", $Samples,
    "-M", $M,
    "-N", $N,
    "-K", $K,
    "-PrecisionProfile", $Profile,
    "-Out", $ProfileOut,
    "-MeanRelErrorLimit", $MeanRelErrorLimit,
    "-MaxRelErrorLimit", $MaxRelErrorLimit
  )
  if ($NoThresholdCheck.IsPresent) {
    $Args += "-NoThresholdCheck"
  }

  & powershell @Args
  if ($LASTEXITCODE -ne 0) {
    throw ("profile run failed: {0}" -f $Profile)
  }

  $Stats = Get-Content -Raw $ProfileOut | ConvertFrom-Json
  if ($Stats.thresholds.status -eq "fail") {
    $Failures += ("profile {0} threshold status failed" -f $Profile)
  }

  $ProfileResults += [ordered]@{
    profile = $Profile
    report = Resolve-Path -Relative $ProfileOut
    seed_count = [int]$Stats.seed_count
    samples_per_seed = [int]$Stats.samples_per_seed
    total_samples = [int]$Stats.total_samples
    mean_abs_error = [double]$Stats.aggregate.mean_abs_error
    mean_rel_error = [double]$Stats.aggregate.mean_rel_error
    max_abs_error = [double]$Stats.aggregate.max_abs_error
    max_abs_error_seed = [int]$Stats.aggregate.max_abs_error_seed
    max_rel_error = [double]$Stats.aggregate.max_rel_error
    max_rel_error_seed = [int]$Stats.aggregate.max_rel_error_seed
    threshold_status = [string]$Stats.thresholds.status
  }
}

$Result = [ordered]@{
  kind = "sampled_matmul_stats_precision_profiles"
  generated_by = "sim/run_matmul_precision_profiles.ps1"
  generated_at_utc = (Get-Date).ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ssZ")
  m = $M
  n = $N
  k = $K
  k_blocks = [int]($K / 32)
  profiles = @($ProfileList)
  seeds = @($Seeds)
  samples_per_seed = $Samples
  thresholds = [ordered]@{
    enabled = (-not $NoThresholdCheck.IsPresent)
    mean_rel_error_limit = $MeanRelErrorLimit
    max_rel_error_limit = $MaxRelErrorLimit
    status = $(if ($Failures.Count -eq 0) { "pass" } else { "fail" })
    failures = @($Failures)
  }
  per_profile = @($ProfileResults)
  note = "Profile summary over deterministic multi-seed sampled stats. Baseline preserves the existing sampled distribution; narrow-scale constrains finite E8M0 scale coverage; wide-scale expands finite E8M0 scale coverage."
}

$Result | ConvertTo-Json -Depth 12 | Set-Content -Encoding ascii -Path $OutPath

if ($Failures.Count -gt 0) {
  throw ("precision profile thresholds failed: {0}" -f ($Failures -join "; "))
}

Write-Host "PASS run_matmul_stats_profiles $OutPath"
