# Frontend Precision Profiles Acceptance Final

## Scope

- Workspace: `D:\github\-`
- Date: `2026-05-10`
- Phase: frontend precision evidence hardening
- In scope: Python sampled precision profile control, multi-seed wrapper profile passthrough, profile summary JSON, README/STATUS updates
- Out of scope: RTL edits, synthesis, SDC, netlist, PPA, packaging, and restoring previously deleted history

## Three-Agent Split

- Planning agent: selected precision profile coverage as the next smallest useful frontend evidence extension after multi-seed statistics.
- Execution lane: added profile control to the Python reference path and wired it through the PowerShell multi-seed/profile wrappers.
- Review agent: required each profile to have an explicit definition, independent JSON evidence, threshold status, and worst-case tracking.

## Objective

Add a controlled precision profile lane on top of sampled stats and the
multi-seed wrapper so frontend precision evidence covers the existing baseline
distribution plus narrower and wider finite E8M0 scale distributions.

## Implementation

- Added `--precision-profile` to `tools/mx_ref.py --report-matmul-stats`.
- Preserved `baseline` as the default profile to keep old sampled stats behavior compatible.
- Added `narrow-scale`, which keeps the finite E4M3 element set and constrains E8M0 scale coverage from `2^-1` through `2^1`.
- Added `wide-scale`, which keeps the finite E4M3 element set and expands E8M0 scale coverage from `2^-6` through `2^6`.
- Updated `sim/run_matmul_stats_multiseed.ps1` to pass the selected profile into the Python reference and record `precision_profile` in JSON.
- Added `sim/run_matmul_precision_profiles.ps1` to run multiple profiles and write a cross-profile summary JSON.

## Default Command

```powershell
.\sim\run_matmul_precision_profiles.ps1
```

Default parameters:

- Shape: `4096x4096x4096`
- Profiles: `baseline`, `narrow-scale`, `wide-scale`
- Seeds: `20260508`, `20260509`, `20260510`
- Samples per seed per profile: `256`
- Total sampled points per profile: `768`
- Summary output: `reports/matmul_stats_4096x4096x4096_profiles.json`
- Per-profile outputs:
  - `reports/matmul_stats_4096x4096x4096_baseline_multiseed.json`
  - `reports/matmul_stats_4096x4096x4096_narrow-scale_multiseed.json`
  - `reports/matmul_stats_4096x4096x4096_wide-scale_multiseed.json`
- Guardrail: `mean_rel_error <= 1.0e-5`
- Guardrail: `max_rel_error <= 1.0e-3`

The wrapper accepts `-Profiles`, `-Seeds`, `-Samples`, `-M`, `-N`, `-K`,
`-Out`, `-MeanRelErrorLimit`, `-MaxRelErrorLimit`, and `-NoThresholdCheck`.

## Fresh Verification

- `python .\tools\mx_ref.py --selftest` -> PASS
- `.\sim\run_matmul_stats_multiseed.ps1 -Seeds 1,2 -Samples 2 -M 64 -N 64 -K 64 -PrecisionProfile narrow-scale -Out reports\matmul_stats_multiseed_narrowscale_smoke_tmp.json -NoThresholdCheck` -> PASS
- `.\sim\run_matmul_precision_profiles.ps1 -Seeds 1,2 -Samples 2 -M 64 -N 64 -K 64 -Out reports\matmul_stats_profiles_smoke_tmp.json -NoThresholdCheck` -> PASS
- `.\sim\run_matmul_precision_profiles.ps1` -> PASS
- `.\sim\run_matmul_stats_multiseed.ps1` -> PASS
- `.\sim\run_frontend_regression.ps1` -> PASS

Temporary smoke JSON files were removed after the parameterized smoke checks.

## Generated Evidence Summary

From `reports/matmul_stats_4096x4096x4096_profiles.json`:

- `kind`: `sampled_matmul_stats_precision_profiles`
- `profiles`: `baseline`, `narrow-scale`, `wide-scale`
- `samples_per_seed`: `256`
- Threshold status: `pass`
- `baseline` total sampled points: `768`
- `baseline` aggregate `mean_abs_error`: `0.00013348863770564398`
- `baseline` aggregate `mean_rel_error`: `5.2222516477843733e-07`
- `baseline` aggregate `max_abs_error`: `0.0011601448059082031`
- `baseline` aggregate `max_rel_error`: `8.614648161471103e-05`
- `narrow-scale` total sampled points: `768`
- `narrow-scale` aggregate `mean_abs_error`: `5.240862568219503e-05`
- `narrow-scale` aggregate `mean_rel_error`: `3.0651760345498153e-07`
- `narrow-scale` aggregate `max_abs_error`: `0.0004320144653320313`
- `narrow-scale` aggregate `max_rel_error`: `1.9880900154143247e-05`
- `wide-scale` total sampled points: `768`
- `wide-scale` aggregate `mean_abs_error`: `0.020422043455861665`
- `wide-scale` aggregate `mean_rel_error`: `4.010936602370008e-07`
- `wide-scale` aggregate `max_abs_error`: `0.15652231872081757`
- `wide-scale` aggregate `max_rel_error`: `5.247795344647414e-05`

## Acceptance Assessment

PASS for the 2026-05-10 frontend precision profile wrapper batch.

This adds controlled profile selection without changing RTL. The default
`baseline` path preserves existing sampled precision behavior, `narrow-scale`
adds a constrained scale lane, and `wide-scale` gives a deterministic
wider-scale stress lane. All default profiles pass the current relative-error
guardrails.

## Remaining Limits

- The evidence is sampled diagnostic precision evidence, not a full `4096 x 4096` output dump.
- The profile lane is Python reference based; RTL functional correctness still comes from `.\sim\run_iverilog.ps1`.
- These profiles expand finite scale coverage only; they do not add new nonfinite injection coverage.
- The wrapper is not part of `.\sim\run_frontend_regression.ps1` yet, to keep the normal regression runtime stable.
- Synthesis, SDC, netlist, timing, area, and power remain outside this phase.
