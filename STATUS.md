# STATUS

## Current Phase

Frontend RTL restart: write, test, and simulate only.

## Latest Acceptance

- 2026-05-10 frontend regression lane final accepted.
- Acceptance final: `reports/acceptance_2026-05-10_frontend_regression_lane.md`.
- Recommended regression entry: `.\sim\run_frontend_regression.ps1`.
- Regression gates passed: `python .\tools\mx_ref.py --selftest`, `.\sim\run_iverilog.ps1`, `.\sim\run_waveform_smoke.ps1`, `.\sim\run_matmul_stats.ps1`.
- 2026-05-10 multi-seed sampled precision evidence final accepted.
- Multi-seed acceptance final: `reports/acceptance_2026-05-10_frontend_precision_multiseed.md`.
- Multi-seed command: `.\sim\run_matmul_stats_multiseed.ps1`.
- Multi-seed report: `reports/matmul_stats_4096x4096x4096_multiseed.json`.
- Multi-seed defaults: seeds `20260508,20260509,20260510`, 256 samples per seed, 768 total sampled points, `mean_rel_error <= 1.0e-5`, `max_rel_error <= 1.0e-3`.
- 2026-05-10 precision profile wrapper final accepted.
- Precision profile acceptance final: `reports/acceptance_2026-05-10_frontend_precision_profiles.md`.
- Precision profile command: `.\sim\run_matmul_precision_profiles.ps1`.
- Precision profile summary: `reports/matmul_stats_4096x4096x4096_profiles.json`.
- Precision profile reports: `reports/matmul_stats_4096x4096x4096_baseline_multiseed.json`, `reports/matmul_stats_4096x4096x4096_narrow-scale_multiseed.json`, `reports/matmul_stats_4096x4096x4096_wide-scale_multiseed.json`.
- Precision profile defaults: profiles `baseline,narrow-scale,wide-scale`, seeds `20260508,20260509,20260510`, 256 samples per seed per profile, `mean_rel_error <= 1.0e-5`, `max_rel_error <= 1.0e-3`.
- 2026-05-09 LLMT / Array e2e directed frontend batch passed.
- Acceptance report: `reports/acceptance_2026-05-09_frontend_e2e_directed.md`.
- Plan record: `.omx/plans/mxfp8_frontend_batch3_e2e_directed_plan_2026-05-09.md`.
- Regression gates passed: `python .\tools\mx_ref.py --selftest`, `.\sim\run_iverilog.ps1`, `.\sim\run_waveform_smoke.ps1`, `.\sim\run_matmul_stats.ps1`.
- 2026-05-09 directed corner expansion frontend batch passed.
- Acceptance report: `reports/acceptance_2026-05-09_frontend_corner_expansion.md`.
- Plan record: `.omx/plans/mxfp8_frontend_batch2_minimal_corner_plan_2026-05-09.md`.
- Regression gates passed: `python .\tools\mx_ref.py --selftest`, `.\sim\run_iverilog.ps1`, `.\sim\run_waveform_smoke.ps1`, `.\sim\run_matmul_stats.ps1`.
- 2026-05-09 subnormal / RNE frontend batch passed.
- Acceptance report: `reports/acceptance_2026-05-09_frontend_subnormal_rne.md`.
- Plan record: `.omx/plans/mxfp8_frontend_batch_plan_2026-05-09.md`.
- Regression gates passed: `python .\tools\mx_ref.py --selftest`, `.\sim\run_iverilog.ps1`, `.\sim\run_waveform_smoke.ps1`, `.\sim\run_matmul_stats.ps1`.

## Active Decisions

- Ignore previous report/package/synthesis history for this phase.
- Keep the design small and readable.
- Do not produce netlist, SDC, area, power, or timing reports yet.
- Use Windows Icarus Verilog for the first simulation loop.

## Implemented Baseline

- `llmt_col`: one MXFP8 dot32 column with FP32 accumulator output.
- `mx_array_32x16`: 16 `llmt_col` instances, A block broadcast, B block per column.
- Basic smoke tests for column accumulation, subnormal element input, NaN propagation, and 16-column array wiring.
- LLMT boundary directed tests for FP32 min subnormal, negative min subnormal, min normal, NaN propagation, idle clear, and post-clear accumulation.
- Array directed test for 16-column independence and per-column `acc_clear_i` behavior.
- Directed `fp32_add_rne` tests for NaN/Inf, cancellation, and round-to-even half-ULP behavior.
- Directed `fixed_to_fp32` and `fp32_add_rne` subnormal boundary tests.
- Expanded directed `fixed_to_fp32` tests for negative subnormal, `nan_i`, overflow, and normal-path RNE ties.
- Expanded directed `fp32_add_rne` tests for signed zero, subnormal-to-normal, and Inf + finite behavior.
- Python-generated `3x20x64` matrix dataset with a Verilog scoreboard test.
- Python-generated `2x17x32` nonfinite matrix dataset with E4M3 NaN and E8M0 scale-NaN propagation.
- Python-generated `4x33x96` random finite matrix dataset with 3 K-blocks and 3 column tiles.
- Python sampled `4096x4096x4096` precision statistics.
- Optional multi-seed sampled `4096x4096x4096` precision statistics wrapper and aggregate report.
- Optional precision-profile sampled `4096x4096x4096` wrapper for baseline, narrow-scale, and wide-scale finite distributions.
- Optional VCD smoke generation for `llmt_col` and `mx_array_32x16` basics.

## Next Work

- Increase sampled stats sample count and add more precision profiles if needed.
- Keep multi-seed precision reports separate from `.\sim\run_frontend_regression.ps1` unless runtime expectations change.
- Only after RTL simulation is stable, revisit synthesis and SDC.
