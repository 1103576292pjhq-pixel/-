# Frontend Regression Lane Acceptance Draft

## Scope

- Workspace: `D:\github\-`
- Date: `2026-05-10`
- Allowed change area for this batch: `README/STATUS/sim/reports`
- Explicitly out of scope: synthesis, SDC, netlist, PPA, packaging, and restoring previously deleted files

## Objective

Make the current frontend-only codebase easier to use by providing one clear
regression entry, aligning the run instructions, and recording fresh
acceptance evidence.

## Batch Changes

- Added `sim/run_frontend_regression.ps1` as the recommended frontend regression entry.
- Updated `README.md` to point to the new wrapper before the individual commands.
- Updated `STATUS.md` with the new batch record and recommended regression command.
- Refreshed acceptance evidence in this report and in `reports/matmul_stats_4096x4096x4096_sampled.json`.

## Regression Chain

The new frontend entry runs these steps in order:

1. `python .\tools\mx_ref.py --selftest`
2. `.\sim\run_iverilog.ps1`
3. `.\sim\run_waveform_smoke.ps1`
4. `.\sim\run_matmul_stats.ps1`

## Fresh Verification Results

- `python .\tools\mx_ref.py --selftest` -> PASS
- `.\sim\run_iverilog.ps1` -> PASS
- `.\sim\run_waveform_smoke.ps1` -> PASS
- `.\sim\run_matmul_stats.ps1` -> PASS
- `.\sim\run_frontend_regression.ps1` -> PASS

## Generated Artifacts

- `reports/matmul_stats_4096x4096x4096_sampled.json`
- `build/tb_llmt_col_basic.vcd`
- `build/tb_mx_array_basic.vcd`

## Acceptance Assessment

Pass for this batch.

The frontend flow is easier to rerun from a clean checkout because the main
regression command is explicit, the README matches the intended workflow, and
the report records a fresh end-to-end pass without widening scope into backend
deliverables.

## Follow-up Candidates

- Add optional multi-seed stats sweep wrappers if precision exploration becomes a repeated frontend task again.
- Keep future README and STATUS changes tied to fresh regression evidence.
