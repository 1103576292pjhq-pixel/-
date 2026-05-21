# Frontend Precision Multi-Seed Acceptance Final

## Scope

- Workspace: `D:\github\-`
- Date: `2026-05-10`
- Phase: frontend precision evidence hardening
- In scope: Python reference sampled precision wrapper, report evidence, README/STATUS updates
- Out of scope: RTL edits, synthesis, SDC, netlist, PPA, packaging, and restoring previously deleted history

## Three-Agent Split

- Planning agent: classified multi-seed sampled statistics as the next frontend precision hardening item rather than a backend or synthesis task.
- Execution agent: added the multi-seed wrapper, generated the aggregate JSON report, and updated frontend status/documentation.
- Review agent: identified the single-seed precision gap and required the wrapper to distinguish script success from threshold-based precision pass/fail.

## Objective

Broaden the existing single-seed sampled `4096x4096x4096` precision evidence to
a deterministic multi-seed run while keeping the current frontend-only boundary.

## Implementation

- Added `sim/run_matmul_stats_multiseed.ps1`.
- Generated `reports/matmul_stats_4096x4096x4096_multiseed.json`.
- Updated `README.md` with the optional multi-seed command and guardrails.
- Updated `STATUS.md` with the final acceptance path and latest precision evidence.

The wrapper reuses `tools/mx_ref.py --report-matmul-stats`; no reference-model
or RTL datapath change was required.

## Default Command

```powershell
.\sim\run_matmul_stats_multiseed.ps1
```

Default parameters:

- Shape: `4096x4096x4096`
- Seeds: `20260508`, `20260509`, `20260510`
- Samples per seed: `256`
- Total sampled points: `768`
- Output: `reports/matmul_stats_4096x4096x4096_multiseed.json`
- Guardrail: `mean_rel_error <= 1.0e-5`
- Guardrail: `max_rel_error <= 1.0e-3`

The wrapper accepts `-Seeds`, `-Samples`, `-M`, `-N`, `-K`, `-Out`,
`-MeanRelErrorLimit`, `-MaxRelErrorLimit`, and `-NoThresholdCheck`.

## Fresh Verification

- `python .\tools\mx_ref.py --selftest` -> PASS
- `.\sim\run_matmul_stats_multiseed.ps1` -> PASS
- `.\sim\run_matmul_stats_multiseed.ps1 -Seeds 1,2 -Samples 2 -M 64 -N 64 -K 64 -Out reports\matmul_stats_multiseed_smoke_tmp.json` -> PASS
- `.\sim\run_frontend_regression.ps1` -> PASS

The temporary smoke JSON was removed after the parameterized smoke check.

## Generated Evidence Summary

From `reports/matmul_stats_4096x4096x4096_multiseed.json`:

- `kind`: `sampled_matmul_stats_multiseed`
- `seed_count`: `3`
- `samples_per_seed`: `256`
- `total_samples`: `768`
- Aggregate `mean_abs_error`: `0.00013348863770564398`
- Aggregate `mean_rel_error`: `5.2222516477843733e-07`
- Aggregate `max_abs_error`: `0.0011601448059082031` at seed `20260509`
- Aggregate `max_rel_error`: `8.614648161471103e-05` at seed `20260508`
- Threshold status: `pass`

## Acceptance Assessment

PASS for the 2026-05-10 frontend precision multi-seed batch.

This improves the frontend precision evidence from one deterministic seed to a
small deterministic seed set with explicit guardrails. It remains sampled
diagnostic evidence, not an exhaustive matrix dump and not backend signoff.

## Remaining Limits

- The sampled run checks 768 output points, not all `4096 x 4096` output positions.
- The precision path is Python reference based; RTL functional correctness still comes from `.\sim\run_iverilog.ps1`.
- More seeds, larger sample counts, and profile-specific distributions can be added later if needed.
- Synthesis, SDC, netlist, timing, area, and power remain outside this phase.
