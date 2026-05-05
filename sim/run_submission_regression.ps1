param(
  [switch]$SkipLongStats,
  [switch]$Fast
)

$ErrorActionPreference = "Stop"
Set-StrictMode -Version 2.0

if ($Fast) {
  $SkipLongStats = $true
}

$Root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$VerificationDir = Join-Path $Root "reports\verification"
$PrecisionDir = Join-Path $Root "reports\precision"
$EvidenceDir = Join-Path $Root "reports\evidence"
$SynthesisDir = Join-Path $Root "reports\synthesis"

New-Item -ItemType Directory -Force -Path $VerificationDir | Out-Null
New-Item -ItemType Directory -Force -Path $PrecisionDir | Out-Null
New-Item -ItemType Directory -Force -Path $EvidenceDir | Out-Null
New-Item -ItemType Directory -Force -Path $SynthesisDir | Out-Null

$FunctionalIssues = New-Object System.Collections.Generic.List[string]
$EvidenceIssues = New-Object System.Collections.Generic.List[string]
$SynthEnvIssues = New-Object System.Collections.Generic.List[string]
$SynthBlockers = New-Object System.Collections.Generic.List[string]
$IndexIssues = New-Object System.Collections.Generic.List[string]

function Write-Stage {
  param([Parameter(Mandatory = $true)][string]$Name)
  Write-Host ""
  Write-Host "===== $Name ====="
}

function Add-Issue {
  param(
    [Parameter(Mandatory = $true)]$List,
    [Parameter(Mandatory = $true)][string]$Message
  )
  $List.Add($Message) | Out-Null
  Write-Host "ISSUE: $Message"
}

function Test-AnyPath {
  param([Parameter(Mandatory = $true)][string]$Path)
  if ($Path -like "*[*?]*") {
    $matches = Get-ChildItem -Path (Join-Path $Root $Path) -ErrorAction SilentlyContinue
    return [bool]$matches
  }
  return Test-Path -LiteralPath (Join-Path $Root $Path)
}

function Require-Path {
  param(
    [Parameter(Mandatory = $true)]$List,
    [Parameter(Mandatory = $true)][string]$Path
  )
  if (-not (Test-AnyPath -Path $Path)) {
    Add-Issue -List $List -Message "Missing required path: $Path"
  } else {
    Write-Host "OK: $Path"
  }
}

function Require-Content {
  param(
    [Parameter(Mandatory = $true)]$List,
    [Parameter(Mandatory = $true)][string]$Path,
    [Parameter(Mandatory = $true)][string]$Pattern,
    [Parameter(Mandatory = $true)][string]$Description
  )
  $fullPath = Join-Path $Root $Path
  if (-not (Test-Path -LiteralPath $fullPath)) {
    Add-Issue -List $List -Message "Missing required path for content check: $Path"
    return
  }
  $content = Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8
  if ($content -notmatch $Pattern) {
    Add-Issue -List $List -Message "Missing content in ${Path}: $Description"
  } else {
    Write-Host "OK: ${Path} contains $Description"
  }
}

function Invoke-LoggedScript {
  param(
    [Parameter(Mandatory = $true)][string]$Label,
    [Parameter(Mandatory = $true)][string]$ScriptPath,
    [string]$LogPath = "",
    [switch]$ScriptOwnsLog
  )

  if (-not (Test-Path -LiteralPath $ScriptPath)) {
    throw "Missing script: $ScriptPath"
  }

  Write-Host "RUN: $Label"
  if ($ScriptOwnsLog) {
    & $ScriptPath
    if ($LASTEXITCODE -ne 0) {
      throw "$Label failed with exit code $LASTEXITCODE"
    }
    return
  }

  $output = @()
  $exitCode = 0
  try {
    $output = & $ScriptPath *>&1
    if ($null -ne $LASTEXITCODE) {
      $exitCode = [int]$LASTEXITCODE
    }
  } catch {
    $output += $_
    $exitCode = 1
  }

  foreach ($line in $output) {
    Write-Host "$line"
  }

  if ($LogPath) {
    $output | ForEach-Object { "$_" } | Set-Content -LiteralPath $LogPath -Encoding UTF8
  }

  if ($exitCode -ne 0) {
    throw "$Label failed with exit code $exitCode"
  }
}

function Search-Text {
  param(
    [Parameter(Mandatory = $true)][string]$Pattern,
    [Parameter(Mandatory = $true)][string[]]$Paths
  )

  $existingPaths = @()
  foreach ($Path in $Paths) {
    if (Test-Path -LiteralPath (Join-Path $Root $Path)) {
      $existingPaths += $Path
    }
  }
  if (-not $existingPaths.Count) {
    return @()
  }

  $rg = Get-Command rg -ErrorAction SilentlyContinue
  if ($rg) {
    try {
      $rgArgs = @(
        "--line-number",
        "--no-heading",
        "--color", "never",
        "--glob", "!.git/**",
        "--glob", "!.omx/**",
        "--glob", "!.codexpotter/**",
        "--glob", "!work/**",
        "--glob", "!dist/**",
        $Pattern
      ) + $existingPaths
      $output = & $rg.Source @rgArgs 2>&1
      if ($LASTEXITCODE -eq 0) {
        return @($output | ForEach-Object { "$_" })
      }
      if ($LASTEXITCODE -eq 1) {
        return @()
      }
      Write-Host "WARN: rg failed; falling back to PowerShell Select-String."
    } catch {
      Write-Host "WARN: rg failed; falling back to PowerShell Select-String."
    }
  }

  $files = @()
  foreach ($Path in $existingPaths) {
    $item = Get-Item -LiteralPath (Join-Path $Root $Path) -ErrorAction SilentlyContinue
    if ($null -eq $item) {
      continue
    }
    if ($item.PSIsContainer) {
      $files += Get-ChildItem -LiteralPath $item.FullName -Recurse -File | Where-Object {
        $_.FullName -notmatch "\\\.git\\|\\\.omx\\|\\\.codexpotter\\|\\work\\|\\dist\\"
      }
    } else {
      $files += $item
    }
  }

  $matches = @()
  foreach ($match in ($files | Select-String -Pattern $Pattern -ErrorAction SilentlyContinue)) {
    $rel = Resolve-Path -LiteralPath $match.Path -Relative
    $matches += ("{0}:{1}:{2}" -f $rel.TrimStart(".\"), $match.LineNumber, $match.Line.Trim())
  }
  return $matches
}

function Assert-NoMatches {
  param(
    [Parameter(Mandatory = $true)]$List,
    [Parameter(Mandatory = $true)][string]$Description,
    [Parameter(Mandatory = $true)][string]$Pattern,
    [Parameter(Mandatory = $true)][string[]]$Paths
  )

  $matches = @(Search-Text -Pattern $Pattern -Paths $Paths)
  if ($matches.Count) {
    Add-Issue -List $List -Message "$Description found:`n$($matches -join "`n")"
  } else {
    Write-Host "OK: $Description not found"
  }
}

function Assert-NoUnsupportedPpaClaims {
  $pattern = "(真实\s*28nm.*(已完成|已达成|达到|达成|实现|signoff\s*(通过|pass))|已完成\s*真实\s*28nm|真实\s*(面积|功耗|频率|时序)\s*[:=]\s*[-+]?\d|WNS\s*[:=]\s*[-+]?\d|TNS\s*[:=]\s*[-+]?\d)"
  $safeContext = "(不|未|无|没有|不能|不可|不得|禁止|阻塞|等待|缺少|缺|模板|外部|blocked|not|no|without|example|示例|口径|待补)"
  $rawMatches = @(Search-Text -Pattern $pattern -Paths @("README.md", "MAIN.md", "STATUS.md", "docs", "reports", "synth", "constraints"))
  $unsafe = @()
  foreach ($line in $rawMatches) {
    if ($line -notmatch $safeContext) {
      $unsafe += $line
    }
  }
  if ($unsafe.Count) {
    Add-Issue -List $IndexIssues -Message "Unsupported real 28nm PPA claim found:`n$($unsafe -join "`n")"
  } else {
    Write-Host "OK: unsupported real 28nm PPA claims not found"
  }
}

function Test-MarkdownPathReferences {
  param(
    [Parameter(Mandatory = $true)]$List,
    [Parameter(Mandatory = $true)][string]$MarkdownPath
  )

  $fullPath = Join-Path $Root $MarkdownPath
  if (-not (Test-Path -LiteralPath $fullPath)) {
    Add-Issue -List $List -Message "Missing markdown file for path-reference check: $MarkdownPath"
    return
  }

  $content = Get-Content -LiteralPath $fullPath -Raw -Encoding UTF8
  $matches = [regex]::Matches($content, '`([^`]+\.(md|ps1|py|v|vh|vcd|png|json|log|sdc|tcl|ys|hex))`')
  $refs = New-Object System.Collections.Generic.HashSet[string]
  foreach ($match in $matches) {
    $ref = $match.Groups[1].Value.Trim()
    if (($ref -match '\s') -or ($ref -match '[:=]') -or ($ref.StartsWith('http'))) {
      continue
    }
    $normalizedRef = $ref -replace '^[./\\]+', ''
    $refs.Add($normalizedRef) | Out-Null
  }

  foreach ($ref in $refs) {
    if (-not (Test-AnyPath -Path $ref)) {
      Add-Issue -List $List -Message "${MarkdownPath} references missing path: $ref"
    }
  }
}

function Test-DistExclusions {
  param([Parameter(Mandatory = $true)]$List)

  $distRoot = Join-Path $Root "dist"
  if (-not (Test-Path -LiteralPath $distRoot)) {
    Add-Issue -List $List -Message "Missing dist directory"
    return
  }

  $package = Get-ChildItem -LiteralPath $distRoot -Directory -Filter "mxfp8_npu_submission_*" |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
  if (-not $package) {
    Add-Issue -List $List -Message "Missing dist/mxfp8_npu_submission_YYYYMMDD package directory"
    return
  }

  $forbidden = Get-ChildItem -LiteralPath $package.FullName -Recurse -Force | Where-Object {
    $_.FullName -match "\\(\.git|\.omx|\.codexpotter|work)(\\|$)" -or $_.Extension -eq ".vvp"
  }
  if ($forbidden) {
    $rel = $forbidden | Select-Object -First 20 | ForEach-Object {
      Resolve-Path -LiteralPath $_.FullName -Relative
    }
    Add-Issue -List $List -Message "Forbidden internal/generated files found in package:`n$($rel -join "`n")"
  } else {
    Write-Host "OK: package excludes internal state and .vvp files"
  }
}

Write-Stage "Preflight"
$requiredPreflight = @(
  "README.md",
  "MAIN.md",
  "STATUS.md",
  "rtl/mx_array_32x16.v",
  "rtl/llmt_col.v",
  "tb/tb_mx_array_dataset.v",
  "tools/mx_ref.py",
  "sim/run_iverilog.ps1",
  "sim/run_python_ref.ps1",
  "sim/run_waveform_smoke.ps1",
  "sim/render_waveform_screenshots.ps1",
  "constraints/mx_array_32x16.sdc",
  "synth/run_dc_template.tcl",
  "synth/run_yosys_generic.ys"
)
foreach ($path in $requiredPreflight) {
  Require-Path -List $SynthEnvIssues -Path $path
}

$frontEndTools = @("iverilog", "vvp", "python")
foreach ($tool in $frontEndTools) {
  $cmd = Get-Command $tool -ErrorAction SilentlyContinue
  if (-not $cmd) {
    Add-Issue -List $SynthEnvIssues -Message "Missing required frontend tool: $tool"
  } else {
    Write-Host ("OK: {0} -> {1}" -f $tool, $cmd.Source)
  }
}

$optionalViewTool = Get-Command gtkwave -ErrorAction SilentlyContinue
if ($optionalViewTool) {
  Write-Host ("OK: gtkwave -> {0}" -f $optionalViewTool.Source)
} else {
  Write-Host "INFO: gtkwave not found; PNG renderer remains the evidence path."
}

$backendTools = @("yosys", "openroad", "verilator", "dc_shell", "genus", "innovus")
$availableBackendTools = @()
foreach ($tool in $backendTools) {
  $cmd = Get-Command $tool -ErrorAction SilentlyContinue
  if ($cmd) {
    $availableBackendTools += $tool
    Write-Host ("OK: {0} -> {1}" -f $tool, $cmd.Source)
  } else {
    Write-Host "INFO: backend tool not found: $tool"
  }
}
if (-not $availableBackendTools.Count) {
  Add-Issue -List $SynthBlockers -Message "BLOCKED_NO_SYNTH_TOOL: no yosys/openroad/verilator/dc_shell/genus/innovus entry found on PATH"
}

$libFiles = Get-ChildItem -LiteralPath $Root -Recurse -File -ErrorAction SilentlyContinue | Where-Object {
  ($_.Extension -in @(".db", ".lib")) -and ($_.FullName -notmatch "\\\.git\\|\\\.omx\\|\\\.codexpotter\\|\\dist\\")
}
if (-not $libFiles) {
  Add-Issue -List $SynthBlockers -Message "BLOCKED_NO_28NM_LIB: no real .db/.lib file found in workspace"
} else {
  Write-Host "OK: candidate .db/.lib files found"
}

Assert-NoMatches `
  -List $SynthEnvIssues `
  -Description "SystemVerilog-only syntax in rtl/tb" `
  -Pattern "\b(package|logic|always_ff)\b|import\s+mx_pkg|task\s+automatic" `
  -Paths @("rtl", "tb")

Write-Stage "Functional"
if ($SynthEnvIssues.Count -eq 0) {
  try {
    Invoke-LoggedScript `
      -Label "Verilog default regression" `
      -ScriptPath (Join-Path $Root "sim\run_iverilog.ps1") `
      -LogPath (Join-Path $VerificationDir "iverilog_default.log")
  } catch {
    Add-Issue -List $FunctionalIssues -Message $_.Exception.Message
  }

  try {
    Invoke-LoggedScript `
      -Label "Python reference self-test and dot32 vector refresh" `
      -ScriptPath (Join-Path $Root "sim\run_python_ref.ps1") `
      -LogPath (Join-Path $VerificationDir "python_ref_default.log")
  } catch {
    Add-Issue -List $FunctionalIssues -Message $_.Exception.Message
  }

  Require-Content -List $FunctionalIssues -Path "reports/verification/iverilog_default.log" -Pattern "PASS:" -Description "PASS markers"
  Require-Content -List $FunctionalIssues -Path "reports/verification/python_ref_default.log" -Pattern "selftest|PASS|Wrote|wrote" -Description "Python self-test/vector output"
} else {
  Add-Issue -List $FunctionalIssues -Message "Functional stage skipped because preflight frontend requirements failed."
}

Write-Stage "Evidence"
if ($FunctionalIssues.Count -eq 0 -and $SynthEnvIssues.Count -eq 0) {
  try {
    Invoke-LoggedScript `
      -Label "Waveform smoke VCD generation" `
      -ScriptPath (Join-Path $Root "sim\run_waveform_smoke.ps1") `
      -ScriptOwnsLog
  } catch {
    Add-Issue -List $EvidenceIssues -Message $_.Exception.Message
  }

  try {
    Invoke-LoggedScript `
      -Label "Waveform PNG rendering" `
      -ScriptPath (Join-Path $Root "sim\render_waveform_screenshots.ps1") `
      -LogPath (Join-Path $VerificationDir "waveform_screenshots.log")
  } catch {
    Add-Issue -List $EvidenceIssues -Message $_.Exception.Message
  }
}

foreach ($path in @(
    "reports/verification/waveform_smoke.log",
    "reports/evidence/waveforms/tb_llmt_col_smoke_wave.vcd",
    "reports/evidence/waveforms/tb_llmt_col_back_to_back_wave.vcd",
    "reports/evidence/waveforms/tb_mx_array_smoke_wave.vcd",
    "reports/evidence/waveform_screenshots/tb_llmt_col_smoke.png",
    "reports/evidence/waveform_screenshots/tb_llmt_col_back_to_back.png",
    "reports/evidence/waveform_screenshots/tb_mx_array_smoke.png"
  )) {
  Require-Path -List $EvidenceIssues -Path $path
}

Write-Stage "Precision"
$precisionEvidence = @(
  "reports/verification/matmul_stats_default.log",
  "reports/verification/matmul_stats_sweep.log",
  "reports/verification/matmul_stats_profiles.log",
  "reports/precision/matmul_stats_4096x4096x4096.json",
  "reports/precision/matmul_stats_4096x4096x4096_sweep.json",
  "reports/precision/matmul_stats_4096x4096x4096_profiles.json",
  "reports/precision/matmul_stats_4096x4096x4096_sparse_nonfinite_sweep.json"
)

if ($SkipLongStats) {
  Write-Host "INFO: -SkipLongStats/-Fast enabled. Long 4096 stats are treated as existing baseline evidence, not as freshly rerun release stats."
  foreach ($path in $precisionEvidence) {
    Require-Path -List $EvidenceIssues -Path $path
  }
} else {
  try {
    Invoke-LoggedScript `
      -Label "4096 sampled stats default release rerun" `
      -ScriptPath (Join-Path $Root "sim\run_matmul_stats.ps1") `
      -LogPath (Join-Path $VerificationDir "matmul_stats_default.log")
  } catch {
    Add-Issue -List $EvidenceIssues -Message $_.Exception.Message
  }

  try {
    Invoke-LoggedScript `
      -Label "4096 sampled stats sweep release rerun" `
      -ScriptPath (Join-Path $Root "sim\run_matmul_stats_sweep.ps1") `
      -LogPath (Join-Path $VerificationDir "matmul_stats_sweep.log")
  } catch {
    Add-Issue -List $EvidenceIssues -Message $_.Exception.Message
  }

  try {
    Invoke-LoggedScript `
      -Label "4096 sampled profile release rerun" `
      -ScriptPath (Join-Path $Root "sim\run_matmul_stats_profiles.ps1") `
      -LogPath (Join-Path $VerificationDir "matmul_stats_profiles.log")
  } catch {
    Add-Issue -List $EvidenceIssues -Message $_.Exception.Message
  }

  foreach ($path in $precisionEvidence) {
    Require-Path -List $EvidenceIssues -Path $path
  }
}

Write-Stage "Index"
foreach ($path in @(
    "reports/evidence/final_evidence_index_2026-05-06.md",
    "reports/evidence/boundary_case_matrix.md",
    "reports/synthesis/environment_check_2026-05-06.md",
    "docs/usage/02_synthesis_environment_check.md",
    "docs/admin/final_submission_manifest.md",
    "docs/report/submission_report.md",
    "docs/report/12_backend_handoff_checklist.md",
    "STATUS.md",
    "MAIN.md",
    "README.md",
    "docs/report/README.md",
    "docs/usage/README.md",
    "reports/evidence/README.md",
    "reports/verification/README.md",
    "reports/synthesis/README.md"
  )) {
  Require-Path -List $IndexIssues -Path $path
}

if (-not ((Test-Path -LiteralPath (Join-Path $Root "tools\package_submission.py")) -or (Test-Path -LiteralPath (Join-Path $Root "sim\package_submission.ps1")))) {
  Add-Issue -List $IndexIssues -Message "Missing packaging script: tools/package_submission.py or sim/package_submission.ps1"
}

Require-Content -List $IndexIssues -Path "reports/synthesis/environment_check_2026-05-06.md" -Pattern "BLOCKED_NO_SYNTH_TOOL|yosys|dc_shell|genus" -Description "synthesis tool status"
Require-Content -List $IndexIssues -Path "reports/synthesis/environment_check_2026-05-06.md" -Pattern "BLOCKED_NO_28NM_LIB|\.db|\.lib" -Description "28nm library status"
Require-Content -List $IndexIssues -Path "docs/admin/final_submission_manifest.md" -Pattern "\.codexpotter|\.omx|work/|work\\|\.vvp|\.git" -Description "formal exclusions"
Require-Content -List $IndexIssues -Path "docs/report/submission_report.md" -Pattern "true 28nm|真实 28nm|PPA" -Description "PPA boundary"
Require-Content -List $IndexIssues -Path "docs/report/12_backend_handoff_checklist.md" -Pattern "mx_array_32x16|constraints/mx_array_32x16\.sdc|run_dc_template\.tcl" -Description "backend receiving checklist"

Test-MarkdownPathReferences -List $IndexIssues -MarkdownPath "reports/evidence/final_evidence_index_2026-05-06.md"
Test-MarkdownPathReferences -List $IndexIssues -MarkdownPath "reports/evidence/boundary_case_matrix.md"
Assert-NoUnsupportedPpaClaims
Test-DistExclusions -List $IndexIssues

Write-Stage "Verdict"
$verdict = "PASS"
if ($SynthEnvIssues.Count -gt 0) {
  $verdict = "FAIL_SYNTH_ENV"
} elseif ($FunctionalIssues.Count -gt 0) {
  $verdict = "FAIL_FUNCTIONAL"
} elseif (($EvidenceIssues.Count -gt 0) -or ($IndexIssues.Count -gt 0)) {
  $verdict = "FAIL_EVIDENCE_INCOMPLETE"
} elseif ($SynthBlockers.Count -gt 0) {
  $verdict = "PASS_WITH_EXTERNAL_SYNTH_BLOCKER"
}

if ($SynthBlockers.Count) {
  Write-Host "External synthesis/PPA blockers:"
  foreach ($issue in $SynthBlockers) {
    Write-Host "  - $issue"
  }
}

$allIssueGroups = @(
  @("SynthEnv", $SynthEnvIssues),
  @("Functional", $FunctionalIssues),
  @("Evidence", $EvidenceIssues),
  @("Index", $IndexIssues)
)
foreach ($group in $allIssueGroups) {
  $name = $group[0]
  $items = $group[1]
  if ($items.Count) {
    Write-Host "$name issues:"
    foreach ($issue in $items) {
      Write-Host "  - $issue"
    }
  }
}

Write-Host "VERDICT: $verdict"
$verdict

if ($verdict -in @("FAIL_FUNCTIONAL", "FAIL_EVIDENCE_INCOMPLETE", "FAIL_SYNTH_ENV")) {
  exit 1
}
exit 0
